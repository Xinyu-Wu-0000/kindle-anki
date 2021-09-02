import .bing_dict

function build_html(w::bing_dict.word, word::DataFrameRow{DataFrame,DataFrames.Index}, prev_source::String="")
    front = "<h1>" * w.word * "</h1>"
    front *= "<div>"
    front *= "<a>" * w.phonetic_symbol_US * "</a>" * "<span>[sound:" * w.pronunciation_US * "]</span>"
    front *= "<a>" * w.phonetic_symbol_EN * "</a>" * "<span>[sound:" * w.pronunciation_EN * "]</span>"
    front *= "</div>"
    if prev_source == ""
        source = "<span style=\"font-size: xx-large\">Source:</span><br>"
    else
        source = prev_source * "<br>"
    end
    source *= "<div style=\"margin-left: 5%;margin-right: 5%;\">"
    source *= "<div style=\"text-align: left;\">"
    source_ = match(Regex("^(.*?)$(word["word_key"])(.*?)\$"), word["usage"])
    source *= source_[1] * "<a>" * word["word_key"] * "</a>" * source_[2]
    source *= "</div>"
    source *= "<div style=\"text-align: right;\">"
    source *= "--" * word["book_key"]
    source *= "</div>"
    source *= "</div>"
    back = "<div>"
    for img in w.images
        back *= "<img src=\"" * img * "\">"
    end
    back *= "</div>"
    back *= "<div style=\"text-align: left;margin-left: 5%;\">词义总结:<div style=\"text-align: left;margin-left: 5%;font-size: medium;\">"
    for meaning in w.meaning_summary
        back *= "<div><a>" * meaning["POS"] * (meaning["POS"] == "网络" ? ": </a><span>" : " </a><span>") * meaning["meaning"] * "</span></div>"
    end
    back *= "</div></div>"
    if length(w.transformation) > 0
        back *= "<div style=\"text-align: left;margin-left: 5%;\">单词变形:<div style=\"text-align: left;margin-left: 5%;\">"
        for transformation in w.transformation
            back *= "<span>" * transformation["transform type"] * " </span><a href=\"" * transformation["transformation link"] * "\">" * transformation["transformation"] * " </a>"
        end
        back *= "</div></div>"
    end
    if length(w.collocate) > 0
        back *= "<div style=\"text-align: left;margin-left: 5%;font-size: medium;\">搭配:"
        for collocate in w.collocate
            back *= "<div style=\"text-align: left;margin-left: 5%;\">"
            back *= "<span>" * collocate.first * " </span>"
            if length(collocate.second) > 1
                for col in collocate.second[1:end - 1]
                    back *= "<a href=\"" * col["collocate link"] * "\">" * col["collcate"] * "</a><span>,</span>"
                end
            end
            back *= "<a href=\"" * collocate.second[end]["collocate link"] * "\">" * collocate.second[end]["collcate"] * "</a>"
            back *= "</div>"
        end
        back *= "</div>"
    end
    if length(w.synonym) > 0
        back *= "<div style=\"text-align: left;margin-left: 5%;font-size: medium;\">同义词:"
        for synonym in w.synonym
            back *= "<div style=\"text-align: left;margin-left: 5%;\">"
            back *= "<span>" * synonym.first * " </span>"
            if length(synonym.second) > 1
                for syn in synonym.second[1:end - 1]
                    back *= "<a href=\"" * syn["synonym link"] * "\">" * syn["synonym"] * "</a><span>,</span>"
                end
            end
            back *= "<a href=\"" * synonym.second[end]["synonym link"] * "\">" * synonym.second[end]["synonym"] * "</a>"
            back *= "</div>"
        end
        back *= "</div>"
    end
    if length(w.antonym) > 0
        back *= "<div style=\"text-align: left;margin-left: 5%;font-size: medium;\">反义词:"
        for antonym in w.antonym
            back *= "<div style=\"text-align: left;margin-left: 5%;\">"
            back *= "<span>" * antonym.first * " </span>"
            if length(antonym.second) > 1
                for ant in antonym.second[1:end - 1]
                    back *= "<a href=\"" * ant["antonym link"] * "\">" * ant["antonym"] * "</a><span>,</span>"
                end
            end
            back *= "<a href=\"" * antonym.second[end]["antonym link"] * "\">" * antonym.second[end]["antonym"] * "</a>"
            back *= "</div>"
        end
        back *= "</div>"
    end
    back *= "<br><div style=\"text-align: left;margin-left: 5%;\">权威英汉双解"
    for aurth in w.Authoritative_English_Chinese_Dual_Explanation
        back *= "<div style=\"text-align: left;margin-left: 5%;\"><a>" * aurth.first * "</a>"
            if "Exp" in keys(aurth.second)
                i = 1
                for Exp in aurth.second["Exp"]
                    try
                        back *= "<div style=\"text-align: left;margin-left: 5%;font-size: large;\"><a>" * Exp["summary CN"] * " </a><a>" * Exp["summary EN"] * "</a></div>"
                    catch
                        back *= "<div style=\"text-align: left;margin-left: 5%;font-size: medium;\">" * "<span>$(i).&nbsp;&nbsp;</span>"
                        back *= "<span style=\"color: red;\">$(Exp["info"])</span>"
                        back *= "<span>$(Exp["pattern"])&nbsp;&nbsp;</span>"
                        back *= "<span>$(Exp["detail CN"])&nbsp;&nbsp;</span>"
                        back *= "<span>$(Exp["detail EN"])</span>"
                        back *= "</div>"
                        i += 1
                    end
                end
            end
            if "IDM" in keys(aurth.second)
                back *= "<br><div style=\"text-align: left;border: groove;margin-left: 5%;\"><a>IDM</a>"
                for IDM in aurth.second["IDM"]
                    back *= "<div style=\"font-size: large; margin-left: 5%;\"><a>$(IDM["IDM"])</a>"
                    back *= "<div style=\"font-size: medium; margin-left: 5%;\"><span>$(IDM["meaning CN"])&nbsp;&nbsp;</span><span>$(IDM["meaning EN"])&nbsp;&nbsp;</span><span style=\"color: red;\">$(IDM["infor"])</span></div>"
                    back *= "</div>"
                end
                back *= "</div>"
            end
        back *= "</div>"
    end
    back *= "</div>"
    back *= "<br><div style=\"text-align: left;margin-left: 5%;\">例句"
    for sentence in w.sentence
        back *= "<div style=\"font-size: medium; margin-left: 5%;\">"
        back *= "<div>"
        for word in sentence["EN"]
            try
                back *= "<a href=\"" * word["link"] * "\">" * word["word"] * "</a>"
            catch
                back *= "<span>$(word["word"])</span>"
            end
        end
        back *= "</div>"
        back *= "<div>"
        for word in sentence["CN"]
            try
                back *= "<a href=\"" * word["link"] * "\">" * word["word"] * "</a>"
            catch
                back *= "<span>$(word["word"])</span>"
            end
        end
        try
            back *= "<a href=\"$(sentence["audio"][1]["audio link"])\">$(sentence["audio"][1]["audio source"])</a>[sound:$(sentence["audio"][2]["audio"])]"
        catch
            back *= "[sound:$(sentence["audio"][1]["audio"])]"
        end
        back *= "</div>"
        back *= "</div>"
    end
    back *= "</div>"
    return [w.word,front,source,back]
end
