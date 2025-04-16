open Supibot

let getRandomMessage = (data: ChannelCustomData.oocData) => {
  let messages = data.messages

  let randomNumber = Utils.random(0, messages->Array.length - 1)

  let randomMessage =
    messages
    ->Array.get(randomNumber)
    ->Option.getExn(~message="Couldn't get a random message from the messages")

  randomMessage
}

let formatMessageWithMsg = (msg: ChannelCustomData.oocMessage) => {
  // HACK: Sweden uses the year-month-day format I want
  let formattedDate = msg.date->Date.fromString->Date.toLocaleDateStringWithLocale("sv")

  `(#${msg.id->Int.toString}) [${formattedDate}]: ${msg.text}`
}

let formatRandomMessage = (msg: ChannelCustomData.oocMessage) => {
  "🎲 " ++ formatMessageWithMsg(msg)
}

let dataWithAddedMessage = (data: ChannelCustomData.oocData, msg: string, adder: string) => {
  let messageId = data.currentId + 1

  let newData: ChannelCustomData.oocData = {
    currentId: messageId,
    messages: [
      ...data.messages,
      {id: messageId, text: msg, date: Date.make()->Date.toISOString, addedBy: adder},
    ],
  }

  newData
}

let dataWithRemovedMessageById = (data: ChannelCustomData.oocData, id: int) => {
  let newData: ChannelCustomData.oocData = {
    currentId: data.currentId,
    messages: [...data.messages]->Array.filter(m => m.id != id),
  }

  newData
}

let updatePinnedDataWith = (data: ChannelCustomData.oocData) => {
  ChannelCustomData.set("OOC_MSGS", data)
}

let getMessageWithId = (data: ChannelCustomData.oocData, id) => {
  data.messages->Array.filter(d => d.id == id)
}

let getMaxIdInData = (data: ChannelCustomData.oocData) => {
  if data.messages->Array.at(data.currentId) != None {
    data.currentId
  } else {
    data.messages->Array.map(m => m.id->Int.toFloat)->Math.maxMany->Float.toInt
  }
}

let getLastMessage = (data: ChannelCustomData.oocData) => {
  let maxId = getMaxIdInData(data)

  getMessageWithId(data, maxId)
}

let isInMiddle = (data: ChannelCustomData.oocData, idx: int) => {
  let maxId = getMaxIdInData(data)

  idx < maxId && idx != 0
}

let getClosestId: (array<int>, int) => int = %raw(` 
(arr, target) => {
  let left = 0;
  let right = arr.length - 1;
  let closest = arr[0];

  while (left <= right) {
      const mid = Math.floor((left + right) / 2);

      if (Math.abs(arr[mid] - target) < Math.abs(closest - target)) {
          closest = arr[mid];
      }

      if (arr[mid] === target) {
          return arr[mid];
      }

      if (arr[mid] < target) {
          left = mid + 1;
      } else {
          right = mid - 1;
      }
  }

  return closest;
}
`)

let getCloseSearchResults = (data: ChannelCustomData.oocData, needle: string) => {
  let haystack = data.messages->Array.map(msg => msg.text)

  let searchResults = Utils.selectAllClosestStrings(needle, haystack)

  let result = {
    switch searchResults {
    | None => None
    | Some(results) => {
        let closestResults = results->Array.filter(res => res.includes)

        switch closestResults->Array.length {
        | 0 => None
        | _ => Some(closestResults)
        }
      }
    }
  }

  result
}

let noPinnedMessages = "There aren't any pinned messages yet. You should try pinning something with $$ooc add […]"

let main = (args: array<string>): string => {
  let data = ChannelCustomData.getOoc()

  let arg = args[0]

  let output = switch data {
  | Error(NoMessages) => "It seems like this command is being ran for the first time. Try adding some messages with $$ooc add […]"
  | Ok(dat) =>
    switch arg {
    | None => getRandomMessage(dat)->formatRandomMessage
    | Some(ar) =>
      switch ar {
      | "pin"
      | "add" =>
        if args->Array.length == 1 {
          "You didn't actually provide a message. Add some text after that"
        } else {
          let messageText = args->Array.sliceToEnd(~start=1)->Array.join(" ")

          let newData = dataWithAddedMessage(dat, messageText, executor)

          updatePinnedDataWith(newData)

          `Pinned the message with ID: ${newData.currentId->Int.toString}`
        }
      | "get" =>
        if dat.messages->Array.length == 0 {
          noPinnedMessages
        } else if args->Array.length == 1 {
          "You should provide an ID, like $$ooc get 1. Did you want to get a random message? Try doing $$ooc"
        } else {
          switch args->Array.getUnsafe(1) {
          | "last" => {
              let msg = dat->getLastMessage->Array.at(0)
              switch msg {
              | Some(m) => m->formatMessageWithMsg
              | None => "Tried to get a message that exists, but actually it doesn't exist. Please report this to @treuks"
              }
            }
          | xd =>
            switch xd->Int.fromString {
            | None => `Please provide a number instead of ${args[1]->Option.getUnsafe}`
            | Some(num) => {
                let msg = dat->getMessageWithId(num)->Array.at(0)

                switch msg {
                | None =>
                  let closestNumber = getClosestId(dat.messages->Array.map(m => m.id), num)
                  if isInMiddle(dat, num) {
                    `Looks like that message has been deleted. Did you mean #${closestNumber->Int.toString} ?`
                  } else {
                    `Couldn't find a message with that id. Did you mean #${closestNumber->Int.toString} ?`
                  }
                | Some(m) => m->formatMessageWithMsg
                }
              }
            }
          }
        }
      | "unpin"
      | "delete"
      | "remove" =>
        if dat.messages->Array.length == 0 {
          noPinnedMessages
        } else if args->Array.length == 1 {
          "You should provide an ID, like $$ooc remove 1"
        } else {
          switch args->Array.getUnsafe(1) {
          | "last" => {
              let maxId = getMaxIdInData(dat)
              let messagesWithRemovedMessage = dataWithRemovedMessageById(dat, maxId)

              if messagesWithRemovedMessage.messages->Array.length < dat.messages->Array.length {
                updatePinnedDataWith(messagesWithRemovedMessage)
                `Succesfully removed last message (#${maxId->Int.toString})`
              } else {
                "Couldn't remove message with last ID. Report this to @treuks"
              }
            }
          | xd =>
            switch xd->Int.fromString {
            | None => `Please provide a number instead of ${args[1]->Option.getUnsafe}`
            | Some(num) => {
                let msg = dat->getMessageWithId(num)->Array.at(0)

                switch msg {
                | None =>
                  let closestNumber = getClosestId(dat.messages->Array.map(m => m.id), num)
                  if isInMiddle(dat, num) {
                    `Looks like that message has been deleted already. Did you mean #${closestNumber->Int.toString} ?`
                  } else {
                    `Couldn't find a message with that id. Did you mean #${closestNumber->Int.toString} ?`
                  }
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
      | "search" =>
        if dat.messages->Array.length == 0 {
          noPinnedMessages
        } else if args->Array.length == 1 {
          "You need to put a string to search for after this"
        } else {
          let messageText = args->Array.sliceToEnd(~start=1)->Array.join(" ")

          let searched = getCloseSearchResults(dat, messageText)

          switch searched {
          | None => "Couldn't find anything similar enough."
          | Some(searches) =>
            if searches->Array.length == 1 {
              let searchMsg =
                searches
                ->Array.get(0)
                ->Option.getExn(~message="Couldn't index into the searches array")
              let message =
                dat.messages
                ->Array.get(searchMsg.index)
                ->Option.getExn(~message="Couldn't index into the messages array")

              formatMessageWithMsg(message)
            } else {
              let allChoices = searches->Array.length - 1

              let randomIndex = Utils.random(0, allChoices)

              let leftNum = (randomIndex + 1)->Int.toString
              let rightNum = searches->Array.length->Int.toString

              let choiceThing = `[${leftNum}/${rightNum}]`

              let searchedMessage =
                searches
                ->Array.get(randomIndex)
                ->Option.getExn(~message="Couldn't get a valid random search")

              let message =
                dat.messages
                ->Array.get(searchedMessage.index)
                ->Option.getExn(~message="Couldn't index into the array of messages")

              `${choiceThing} ${formatMessageWithMsg(message)}`
            }
          }
        }
      | _ => "Sorry I don't understand what you're trying to do :( | Available commands: [add, remove, get, search]"
      }
    }
  }

  output->Utils.unping
}
