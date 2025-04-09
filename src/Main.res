open Supibot

let getRandomMessage = ( data: ChannelCustomData.oocData ) => {

    let messages = data.messages

    let randomNumber = 
        (Math.random() *. (messages->Array.length->Int.toFloat))->Float.toInt

    let randomMessage = messages->Array.getUnsafe(randomNumber)

    randomMessage
}

let formatRandomMessage = ( msg: ChannelCustomData.oocMessage ) => {
    // HACK: Sweden uses the year-month-day format I want
    let formattedDate = msg.date->Date.fromString->Date.toLocaleDateStringWithLocale("sv")

    `🎲 (#${msg.id->Int.toString}) [${formattedDate}]: ${msg.text}`
}

let formatMessageWithMsg = ( msg: ChannelCustomData.oocMessage ) => {
    // HACK: Sweden uses the year-month-day format I want
    let formattedDate = msg.date->Date.fromString->Date.toLocaleDateStringWithLocale("sv")

    `(#${msg.id->Int.toString}) [${formattedDate}]: ${msg.text}`
}

let dataWithAddedMessage = ( data: ChannelCustomData.oocData, msg: string, adder: string) => {
    let messageId = data.currentId + 1
    
    let newData: ChannelCustomData.oocData = 
        { 
            currentId: messageId, 
            messages: [ ...data.messages, { id: messageId, text: msg, date: Date.make()->Date.toISOString, addedBy: adder }]
        }
    
    newData
}

let dataWithRemovedMessageById = ( data: ChannelCustomData.oocData, id: int) => {

    let newData: ChannelCustomData.oocData = 
        { 
            currentId: data.currentId, 
            messages: [...data.messages]->Array.filter(m => m.id != id)
        }
    
    newData
}

let updatePinnedDataWith = ( data: ChannelCustomData.oocData ) => {
    ChannelCustomData.set("OOC_MSGS", data)
}

let getMessageWithId = ( data: ChannelCustomData.oocData, id ) => {
    data.messages->Array.filter(d => d.id == id)
}

let getMaxIdInData = ( data: ChannelCustomData.oocData ) => {
    data.messages->Array.map(m => m.id->Int.toFloat)->Math.maxMany->Float.toInt
}

let getLastMessage = ( data: ChannelCustomData.oocData ) => {
    let maxId = getMaxIdInData(data)

    getMessageWithId(data, maxId)
}

let noPinnedMessages = "There aren't any pinned messages yet. You should try pinning something with $$ooc add […]"

let main = ( args: array<string> ): string => {
    let data = ChannelCustomData.getOoc()

    let arg = args[0]

    let output = switch data {
        | Error(NoMessages) => {
            "It seems like this command is being ran for the first time. Try adding some messages with $$ooc add […]"
        }
        | Ok(dat) => {
            switch arg {
                | None => { getRandomMessage(dat)->formatRandomMessage }
                | Some(ar) => {
                    switch ar {
                        | "pin"
                        | "add" => {
                            if args->Array.length == 1 {
                                "You didn't actually provide a message. Add some text after that"
                            } else {
                                let messageText = args->Array.sliceToEnd(~start=1)->Array.join(" ")
                                
                                let newData = dataWithAddedMessage(dat, messageText, executor)
                                
                                updatePinnedDataWith(newData)

                                `Pinned the message with ID: ${newData.currentId->Int.toString}`
                            }
                        }
                        | "get" => {
                            if dat.messages->Array.length == 0 {
                                noPinnedMessages
                            } else {
                                if args->Array.length == 1 {
                                    "You should provide an ID, like $$ooc get 1. Did you want to get a random message? Try doing $$ooc"
                                } else {
                                    switch args->Array.getUnsafe(1) {
                                    | "last" => {
                                        let msg = dat->getLastMessage->Array.at(0)
                                        switch msg {
                                        | Some(m) => m->formatMessageWithMsg
                                        | None => "Trying to get the message with the last id but found multiple. Please report this to @treuks"
                                        }
                                      }
                                    | xd => {
                                        switch xd->Int.fromString {
                                            | None => {
                                                `Please provide a number instead of ${args[1]->Option.getUnsafe}`
                                            }
                                            | Some(num) => {
                                                let msg = dat->getMessageWithId(num)->Array.get(0)

                                                switch msg {
                                                    | None => `Couldn't find a message with that id. Current id is ${dat.currentId->Int.toString}`
                                                    | Some(m) => {
                                                        m->formatMessageWithMsg
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    }
                                }
                            }
                        }
                        | "unpin"
                        | "delete"
                        | "remove" => {
                            if dat.messages->Array.length == 0 {
                                noPinnedMessages
                            } else {
                                if args->Array.length == 1 {
                                    "You should provide an ID, like $$ooc remove 1"
                                } else {
                                    switch args->Array.getUnsafe(1) {
                                    | "last" => {
                                        let messagesWithRemovedMessage = dataWithRemovedMessageById(dat, getMaxIdInData(dat))

                                        if (messagesWithRemovedMessage.messages->Array.length) < (dat.messages->Array.length) {
                                            updatePinnedDataWith(messagesWithRemovedMessage)
                                            "Succesfully removed last message"
                                        } else {
                                            "Couldn't remove message with last ID. Report this to @treuks"
                                        }
                                      }
                                    | xd => {
                                        switch xd->Int.fromString {
                                            | None => {
                                                `Please provide a number instead of ${args[1]->Option.getUnsafe}`
                                            }
                                            | Some(num) => {
                                                let msg = dat->getMessageWithId(num)->Array.get(0)

                                                switch msg {
                                                    | None => `Couldn't find a message with that id. Current id is ${dat.currentId->Int.toString}`
                                                    | Some(m) => {
                                                        let messagesWithRemovedMessage = dataWithRemovedMessageById(dat, m.id)
                                                       
                                                        updatePinnedDataWith(messagesWithRemovedMessage)

                                                        `Succesfully removed message with id ${m.id->Int.toString}`
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    }
                                }
                            }
                        }
                        | "search" => {
                            if dat.messages->Array.length == 0 {
                                noPinnedMessages
                            } else {
                                if args->Array.length == 1 {
                                    "You need to put a string to search for after this"
                                } else {
                                    let messageText = args->Array.sliceToEnd(~start=1)->Array.join(" ")

                                    let allMessages = dat.messages->Array.map(m => m.text)

                                    let searched = Utils.selectClosestString(messageText, allMessages)

                                    switch searched {
                                        | None => {
                                            "Couldn't find anything similar enough."
                                        }
                                        | Some(ms) => {
                                            formatMessageWithMsg(dat.messages->Array.getUnsafe(ms.index))
                                        }
                                    }
                                }
                            }
                        }
                        | _ => {
                            "Sorry I don't understand what you're trying to do :( | Available commands: [add, remove, get, search]"
                        }
                    }
                }
            }
        }
    }

    output->Utils.unping
}
