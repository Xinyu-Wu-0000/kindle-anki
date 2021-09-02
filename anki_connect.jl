using JSON
using HTTP
const anki_addr = "http://127.0.0.1:8765"
const add_deck = "English"

function check_duplicate(word::String)
    findNotes = Dict("action" => "findNotes",
                "action" => "findNotes",
                "version" => 6,
                "params" => Dict(
                            "query" => "deck:$(add_deck) Word:$(word)")
                )
    findNotes = JSON.json(findNotes)
    result = HTTP.post(anki_addr, [], findNotes)
    result = JSON.parse(String(result.body))
    if result["error"] !== nothing
        throw(result["error"])
        return
    end
    if length(result["result"]) > 0
        if length(result["result"]) > 1
            throw("too many duplicates for word : $(word["word_key"])")
            return
        end
        notesInfo = Dict(
            "action" => "notesInfo",
            "version" => 6,
            "params" => Dict(
                "notes" => result["result"]
                )
            )
        notesInfo = JSON.json(notesInfo)
        result = HTTP.post(anki_addr, [], notesInfo)
        result = JSON.parse(String(result.body))
        if result["error"] !== nothing
            throw(result["error"])
            return
        end
        return result["result"][1]
    else
        return nothing
    end
end

function add_note(feilds::Vector{String}, word::DataFrameRow{DataFrame,DataFrames.Index})
    addNote = Dict(
            "action" => "addNote",
            "version" => 6,
            "params" => Dict(
                        "note" => Dict( "deckName" => "$(add_deck)",
                                        "modelName" => "Bing Dictionary",
                                        "fields" => Dict(
                                                        "Word" => feilds[1],
                                                        "Front" => feilds[2],
                                                        "Source" => feilds[3],
                                                        "Back" => feilds[4]
                                                        ),
                                        "options" => Dict(
                                                        "allowDuplicate" => false,
                                                        "duplicateScope" => "deck",
                                                        "duplicateScopeOptions" => Dict(
                                                                                        "deckName" => "$(add_deck)",
                                                                                        "checkChildren" => false,
                                                                                        "checkAllModels" => false
                                                                                        )
                                                        ),
                                        "tags" => ["kindle","$(word["book_key"])"]
                                    )
                        )
            )
    addNote = JSON.json(addNote)
    result = HTTP.post(anki_addr, [], addNote)
    result = JSON.parse(String(result.body))
    if result["error"] !== nothing
        throw(result["error"])
        return
    end
    return result["result"]
end

function update_note(feilds::Vector{String}, word::DataFrameRow{DataFrame,DataFrames.Index}, duplicate::Int64, tags::Vector{Any})
    if word["book_key"] ∉ tags
        addTags = Dict(
                "action" => "addTags",
                "version" => 6,
                "params" => Dict(
                        "notes" => [duplicate],
                        "tags" => "$(word["book_key"])"
                        )
                )
        addTags = JSON.json(addTags)
        result = HTTP.post(anki_addr, [], addTags)
        result = JSON.parse(String(result.body))
        if result["error"] !== nothing
            throw(result["error"])
            return
        end
    end
    updateNoteFields = Dict(
                            "action" => "updateNoteFields",
                            "version" => 6,
                            "params" => Dict(
                                        "note" => Dict(
                                                    "id" => duplicate,
                                                    "fields" => Dict(
                                                                    "Word" => feilds[1],
                                                                    "Front" => feilds[2],
                                                                    "Source" => feilds[3],
                                                                    "Back" => feilds[4])
                                                    )
                                        )
                        )
    updateNoteFields = JSON.json(updateNoteFields)
    result = HTTP.post(anki_addr, [], updateNoteFields)
    result = JSON.parse(String(result.body))
    if result["error"] !== nothing
        throw(result["error"])
        return
    end  
    return result["result"]
end
