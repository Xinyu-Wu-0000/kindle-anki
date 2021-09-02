module bing_dict

using EzXML, HTTP, SHA

const connect_timeout, readtimeout, retries = 3, 3, 3
const media_dir = "/home/wuxinyu/.local/share/Anki2/xinyu/collection.media/"
const media_prefix = "BingDictionary"
const proxy = "http://127.0.0.1:1080"
const total_fail = "TOTAL FAIL!"

mutable struct word
    word::String
    lf_area::EzXML.Node
    err_log::Vector{String}
    phonetic_symbol_US::String
    phonetic_symbol_EN::String
    pronunciation_US::String
    pronunciation_EN::String
    meaning_summary::Vector{Dict{String,String}}
    images::Vector{String}
    transformation::Vector{Dict{String,String}}
    collocate::Dict{String,Vector{Dict{String,String}}}
    synonym::Dict{String,Vector{Dict{String,String}}}
    antonym::Dict{String,Vector{Dict{String,String}}}
    Authoritative_English_Chinese_Dual_Explanation::Dict{String,Dict{String,Vector{Dict{String,String}}}}
    sentence::Vector{Dict{String,Vector{Dict{String,String}}}}
    word() = new()
end

function get_lf_area(w::word)
    w.err_log = Vector{String}()
    page = nothing
    try
        page = HTTP.request("GET", "https://cn.bing.com/dict/search?q=$(w.word)", connect_timeout=connect_timeout, readtimeout=readtimeout, retries=retries, redirect=true)
    catch e
        push!(w.err_log, total_fail)
        push!(w.err_log, "can't get page!")
    end
    page = parsehtml(page.body)
    try
        w.lf_area = findfirst("//div[@class='lf_area']", page)
    catch e
        push!(w.err_log, total_fail)
        push!(w.err_log, "can't find left area!")
    end
end

function get_word(w::word)
    w.word = findfirst(".//div[@class='hd_div' and @id='headword']/h1/strong", w.lf_area).content
end


function get_phonetic_symbol_US(w::word)
    w.phonetic_symbol_US = findfirst(".//div[@class='hd_prUS b_primtxt']", w.lf_area).content
end

function get_pronunciation_US(w::word)
    url = match(r"^javascript:BilingualDict\.Click\(this,'(.*?\.mp3)'.*$", firstnode(nextnode(findfirst(".//div[@class='hd_prUS b_primtxt']", w.lf_area)))["onclick"])[1]
    aud = HTTP.request("GET", url, connect_timeout=connect_timeout, readtimeout=readtimeout, retries=retries, redirect=true)
    w.pronunciation_US = media_prefix * bytes2hex(sha2_256(aud.body)) * ".mp3"
    open(media_dir * w.pronunciation_US, "w") do f
        write(f, aud.body)
    end
end

function get_phonetic_symbol_EN(w::word)
    w.phonetic_symbol_EN = findfirst(".//div[@class='hd_pr b_primtxt']", w.lf_area).content
end

function get_pronunciation_EN(w::word)
    url = match(r"^javascript:BilingualDict\.Click\(this,'(.*?\.mp3)'.*$", firstnode(nextnode(findfirst(".//div[@class='hd_pr b_primtxt']", w.lf_area)))["onclick"])[1]
    aud = HTTP.request("GET", url, connect_timeout=connect_timeout, readtimeout=readtimeout, retries=retries, redirect=true)
    w.pronunciation_EN = media_prefix * bytes2hex(sha2_256(aud.body)) * ".mp3"
    open(media_dir * w.pronunciation_EN, "w") do f
        write(f, aud.body)
    end
end

function get_meaning_summary(w::word)
    w.meaning_summary = Vector{Dict{String,String}}()
    for node in findall("li", findfirst(".//div[@class='qdef']/ul", w.lf_area))
        meaning = Dict{String,String}()
        meaning["POS"] = findfirst("./span[@class='pos' or @class='pos web']", node).content
        meaning["meaning"] = findfirst("./span[@class='def b_regtxt']", node).content
        push!(w.meaning_summary, meaning)
    end
end

function get_images(w::word) 
    w.images = Vector{String}()
    for node in findall(".//div[@class='simg']", w.lf_area)
        url = firstnode(firstnode(node))["src"]
        img = HTTP.request("GET", url, connect_timeout=connect_timeout, readtimeout=readtimeout, retries=retries, redirect=true, proxy=proxy)
        imgname = media_prefix * bytes2hex(sha2_256(img.body)) * ".png"
        open(media_dir * imgname, "w") do f
            write(f, img.body)
        end
        push!(w.images, imgname)
    end 
end

function get_word_transformation(w::word)
    w.transformation = Vector{Dict{String,String}}()
    for node in findall(".//div[@class='hd_div1']/div[@class='hd_if']/span[@class='b_primtxt']", w.lf_area)
        push!(w.transformation, Dict("transform type" => node.content, "transformation link" => "https://cn.bing.com" * nextnode(node)["href"], "transformation" => nextnode(node).content))
    end
end

function get_collocate(w::word)
    w.collocate = Dict{String,Vector{Dict{String,String}}}()
    for node in findall(".//div[@id='colid']/div[@class='df_div2']", w.lf_area)
        collocate = Pair{String,Vector{Dict{String,String}}}(findfirst("./div[@class='de_title2 b_dictHighlight']", node).content, [Dict("collocate link" => "https://cn.bing.com" * node_["href"], "collcate" => node_.content) for node_ in findall("./div[@class='col_fl']/a", node)])
        push!(w.collocate, collocate)
    end
end

function get_synonym(w::word)
    w.synonym = Dict{String,Vector{Dict{String,String}}}()
    for node in findall(".//div[@id='synoid']/div[@class='df_div2']", w.lf_area)
        synonym = Pair{String,Vector{Dict{String,String}}}(findfirst("./div[@class='de_title1 b_dictHighlight']", node).content, [Dict("synonym" => node_.content, "synonym link" => "https://cn.bing.com" * node_["href"]) for node_ in findall("./div[@class='col_fl']/a", node)])
        push!(w.synonym, synonym)
    end
end

function get_antonym(w::word)
    w.antonym = Dict{String,Vector{Dict{String,String}}}()
    for node in findall(".//div[@id='antoid']/div[@class='df_div2']", w.lf_area)
        antonym = Pair{String,Vector{Dict{String,String}}}(findfirst("./div[@class='de_title1 b_dictHighlight']", node).content, [Dict("antonym" => node_.content, "antonym link" => "https://cn.bing.com" * node_["href"]) for node_ in findall("./div[@class='col_fl']/a", node)])
        push!(w.antonym, antonym)
    end
end

function get_Authoritative_English_Chinese_Dual_Explanation(w::word)
    w.Authoritative_English_Chinese_Dual_Explanation = Dict{String,Dict{String,Vector{Dict{String,String}}}}()
    for node in findall(".//div[@id='authid']/div[@id='newLeId']/div[@class='each_seg']", w.lf_area)
        each_POS = Dict{String,Vector{Dict{String,String}}}()
        POS = ""
        try
            POS = findfirst("./div[@class='li_pos']/div[@class='pos_lin']/div[@class='pos']", node).content
        catch
            continue
        end
        each_POS["Exp"] = Vector{Dict{String,String}}()
        for node_ in nodes(findfirst(".//div[@class='de_seg']", node))
            if node_["class"] == "dis"
                push!(each_POS["Exp"],Dict("summary CN" => findfirst("./span[@class='bil_dis b_primtxt']", node_).content,
                                            "summary EN" => findfirst("./span[@class='val_dis b_primtxt']", node_).content))
            end
            if node_["class"] == "se_lis"
                s = ""
                for node__ in findall(".//div[@class='au_def']/span", node_)
                    s = s * node__.content * " "
                end
                s_ = ""
                try
                    s_ = findfirst(".//span[@class='comple b_regtxt']", node_).content
                catch 
                    s_ = ""
                end
                push!(each_POS["Exp"], Dict("info" => s,"pattern" => s_,"detail CN" => findfirst(".//div[@class='def_pa']/span[@class='bil b_primtxt']", node_).content,
                 "detail EN" => findfirst(".//div[@class='def_pa']/span[@class='val b_regtxt']", node_).content))
            end
        end
        if length(each_POS["Exp"]) == 0
            delete!(each_POS, "Exp")
        end
        each_POS["IDM"] = Vector{Dict{String,String}}()
        for node_ in findall(".//div[@class='idm_seg']/div[@class='idm_s']", node)
            infor = ""
            try
                infor = findfirst(".//span[@class='infor']", nextnode(node_)).content 
            catch
                infor = ""
            end     
            push!(each_POS["IDM"],Dict("IDM" => firstnode(node_).content,
                                        "infor" => infor,
                                        "meaning EN" => findfirst(".//span[@class='val b_regtxt']", nextnode(node_)).content,
                                        "meaning CN" => findfirst(".//span[@class='val b_regtxt']", nextnode(node_)).content))
        end
        if length(each_POS["IDM"]) == 0
            delete!(each_POS, "IDM")
        end
        w.Authoritative_English_Chinese_Dual_Explanation[POS] = each_POS
    end
end

function get_sentence(w::word)
    w.sentence = Vector{Dict{String,Vector{Dict{String,String}}}}()
    for node in findall(".//div[@id='sentenceSeg']/div[@class='se_li']", w.lf_area)
        sentence = Dict{String,Vector{Dict{String,String}}}()
        sentence["EN"] = Vector{Dict{String,String}}()
        for node_ in nodes(findfirst(".//div[@class='sen_en b_regtxt']", node))
            if node_.name == "a"
                push!(sentence["EN"], Dict("word" => node_.content, "link" => "https://cn.bing.com" * node_["href"])) 
            elseif node_.name == "span"
                push!(sentence["EN"], Dict("word" => node_.content))
            end
        end
        sentence["CN"] = Vector{Dict{String,String}}()
        for node_ in nodes(findfirst(".//div[@class='sen_cn b_regtxt']", node))
            if node_.name == "a"
                push!(sentence["CN"], Dict("word" => node_.content, "link" => "https://cn.bing.com" * node_["href"]))  
            elseif node_.name == "span"
                push!(sentence["CN"], Dict("word" => node_.content))
            end
        end
        url = match(r"^javascript:BilingualDict\.Click\(this,'(.*?\.mp3)'.*$", findfirst(".//a[@class='bigaud']", node)["onmousedown"])[1]
        aud = HTTP.request("GET", url, connect_timeout=connect_timeout, readtimeout=readtimeout, retries=retries, redirect=true)
        audioname = media_prefix * bytes2hex(sha2_256(aud.body)) * ".mp3"
        open(media_dir * audioname, "w") do f
            write(f, aud.body)
        end
        try
            sentence["audio"] = Vector{Dict{String,String}}([Dict("audio source" => findfirst(".//div[@class='sen_li b_regtxt']/a", node).content,
                                                        "audio link" => findfirst(".//div[@class='sen_li b_regtxt']/a", node)["href"]),
                                                        Dict("audio" => audioname)])
        catch
            sentence["audio"] = Vector{Dict{String,String}}([Dict("audio" => audioname)])
        end
        push!(w.sentence, sentence)
    end
end


function get_all(w::word)
    get_lf_area(w)
    if total_fail in w.err_log
        return
    end
    get_word(w)
    get_phonetic_symbol_US(w)
    get_pronunciation_US(w)
    get_phonetic_symbol_EN(w)
    get_pronunciation_EN(w)
    get_meaning_summary(w)
    get_images(w)
    get_word_transformation(w)
    get_collocate(w)
    get_synonym(w)
    get_antonym(w)
    get_Authoritative_English_Chinese_Dual_Explanation(w)
    get_sentence(w)
end

end
