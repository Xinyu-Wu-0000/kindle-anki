using SQLite,DataFrames,JSON
const vocab_dir = "/media/wuxinyu/Kindle/system/vocabulary/vocab.db"

config = JSON.parsefile("config.json")
db = SQLite.DB(vocab_dir)
@info "read data base file complete"
table_names = DataFrame(DBInterface.execute(db, "select name from sqlite_master where type='table';"))
lookups = DataFrame(DBInterface.execute(db, "select * from $(table_names[2,1]);"))
lookups = lookups[lookups[:,"timestamp"] .> config["last_lookups_timestamp"],:]
data = lookups[:,["word_key","book_key","usage","timestamp"]]
for i in 1:length(data[:,"book_key"])
    data[i,"book_key"] = match(r"^(.*?):[0-9 A-Z]*?$", data[i,"book_key"])[1]
end
for i in 1:length(data[:,"word_key"])
    data[i,"word_key"] = match(r"^[a-z][a-z]:(.*)$", data[i,"word_key"])[1]
end
print(data)

include("bing_dict.jl")
include("html_builder.jl")
include("anki_connect.jl")
log = Vector{String}()
log_id = Vector{Int64}()
test = 0
for i in 1:size(data, 1)
    test = i
    word = bing_dict.word()
    word.word = data[i,"word_key"]
    bing_dict.get_all(word)
    if bing_dict.total_fail in word.err_log
        push!(log_id, i)
        push!(log, bing_dict.total_fail)
        continue
    else
        duplicate = check_duplicate(word.word)
        if duplicate === nothing
            feilds = build_html(word, data[i,:])
            add_note(feilds, data[i,:])
        else
            feilds = build_html(word, data[i,:], duplicate["fields"]["Source"]["value"])
            update_note(feilds, data[i,:], duplicate["noteId"], duplicate["tags"])
        end
    end
end

log
log_id
data[log_id,:]

if test != 0
    test
    data[test,:]
end

if size(data, 1) > 0
    config["last_lookups_timestamp"] = maximum(data[!,"timestamp"])
    open("config.json", "w") do f
        write(f, JSON.json(config))
    end
end
