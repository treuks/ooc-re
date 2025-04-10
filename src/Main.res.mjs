// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Supibot from "./Supibot.res.mjs";
import * as Core__Int from "@rescript/core/src/Core__Int.res.mjs";
import * as Belt_Array from "rescript/lib/es6/belt_Array.js";
import * as Caml_splice_call from "rescript/lib/es6/caml_splice_call.js";

function getRandomMessage(data) {
  var messages = data.messages;
  var randomNumber = Math.random() * messages.length | 0;
  return messages[randomNumber];
}

function formatRandomMessage(msg) {
  var formattedDate = new Date(msg.date).toLocaleDateString("sv");
  return "🎲 (#" + msg.id.toString() + ") [" + formattedDate + "]: " + msg.text;
}

function formatMessageWithMsg(msg) {
  var formattedDate = new Date(msg.date).toLocaleDateString("sv");
  return "(#" + msg.id.toString() + ") [" + formattedDate + "]: " + msg.text;
}

function dataWithAddedMessage(data, msg, adder) {
  var messageId = data.currentId + 1 | 0;
  return {
          currentId: messageId,
          messages: Belt_Array.concatMany([
                data.messages,
                [{
                    id: messageId,
                    text: msg,
                    date: new Date().toISOString(),
                    addedBy: adder
                  }]
              ])
        };
}

function dataWithRemovedMessageById(data, id) {
  return {
          currentId: data.currentId,
          messages: Belt_Array.concatMany([data.messages]).filter(function (m) {
                return m.id !== id;
              })
        };
}

function updatePinnedDataWith(data) {
  channelCustomData.set("OOC_MSGS", data);
}

function getMessageWithId(data, id) {
  return data.messages.filter(function (d) {
              return d.id === id;
            });
}

function getMaxIdInData(data) {
  return Caml_splice_call.spliceApply(Math.max, [data.messages.map(function (m) {
                    return m.id;
                  })]) | 0;
}

function getLastMessage(data) {
  var maxId = getMaxIdInData(data);
  return getMessageWithId(data, maxId);
}

var noPinnedMessages = "There aren't any pinned messages yet. You should try pinning something with $$ooc add […]";

function main(args) {
  var data = Supibot.ChannelCustomData.getOoc();
  var arg = args[0];
  var tmp;
  if (data.TAG === "Ok") {
    var dat = data._0;
    if (arg !== undefined) {
      var exit = 0;
      switch (arg) {
        case "get" :
            if (dat.messages.length === 0) {
              tmp = noPinnedMessages;
            } else if (args.length === 1) {
              tmp = "You should provide an ID, like $$ooc get 1. Did you want to get a random message? Try doing $$ooc";
            } else {
              var xd = args[1];
              if (xd === "last") {
                var msg = getLastMessage(dat).at(0);
                tmp = msg !== undefined ? formatMessageWithMsg(msg) : "Trying to get the message with the last id but found multiple. Please report this to @treuks";
              } else {
                var num = Core__Int.fromString(xd, undefined);
                if (num !== undefined) {
                  var msg$1 = getMessageWithId(dat, num)[0];
                  tmp = msg$1 !== undefined ? formatMessageWithMsg(msg$1) : "Couldn't find a message with that id. Current id is " + dat.currentId.toString();
                } else {
                  tmp = "Please provide a number instead of " + args[1];
                }
              }
            }
            break;
        case "add" :
        case "pin" :
            exit = 1;
            break;
        case "search" :
            if (dat.messages.length === 0) {
              tmp = noPinnedMessages;
            } else if (args.length === 1) {
              tmp = "You need to put a string to search for after this";
            } else {
              var messageText = args.slice(1).join(" ");
              var allMessages = dat.messages.map(function (m) {
                    return m.text;
                  });
              var searched = utils.selectClosestString(messageText, allMessages, { ignoreCase: true, descriptor: true });
              tmp = (searched == null) ? "Couldn't find anything similar enough." : formatMessageWithMsg(dat.messages[searched.index]);
            }
            break;
        case "delete" :
        case "remove" :
        case "unpin" :
            exit = 2;
            break;
        default:
          tmp = "Sorry I don't understand what you're trying to do :( | Available commands: [add, remove, get, search]";
      }
      switch (exit) {
        case 1 :
            if (args.length === 1) {
              tmp = "You didn't actually provide a message. Add some text after that";
            } else {
              var messageText$1 = args.slice(1).join(" ");
              var newData = dataWithAddedMessage(dat, messageText$1, executor);
              channelCustomData.set("OOC_MSGS", newData);
              tmp = "Pinned the message with ID: " + newData.currentId.toString();
            }
            break;
        case 2 :
            if (dat.messages.length === 0) {
              tmp = noPinnedMessages;
            } else if (args.length === 1) {
              tmp = "You should provide an ID, like $$ooc remove 1";
            } else {
              var xd$1 = args[1];
              if (xd$1 === "last") {
                var maxId = getMaxIdInData(dat);
                var messagesWithRemovedMessage = dataWithRemovedMessageById(dat, maxId);
                if (messagesWithRemovedMessage.messages.length < dat.messages.length) {
                  channelCustomData.set("OOC_MSGS", messagesWithRemovedMessage);
                  tmp = "Succesfully removed last message (#" + maxId.toString() + ")";
                } else {
                  tmp = "Couldn't remove message with last ID. Report this to @treuks";
                }
              } else {
                var num$1 = Core__Int.fromString(xd$1, undefined);
                if (num$1 !== undefined) {
                  var msg$2 = getMessageWithId(dat, num$1)[0];
                  if (msg$2 !== undefined) {
                    var messagesWithRemovedMessage$1 = dataWithRemovedMessageById(dat, msg$2.id);
                    channelCustomData.set("OOC_MSGS", messagesWithRemovedMessage$1);
                    tmp = "Succesfully removed message with id " + msg$2.id.toString();
                  } else {
                    tmp = "Couldn't find a message with that id. Current id is " + dat.currentId.toString();
                  }
                } else {
                  tmp = "Please provide a number instead of " + args[1];
                }
              }
            }
            break;
        
      }
    } else {
      tmp = formatRandomMessage(getRandomMessage(dat));
    }
  } else {
    tmp = "It seems like this command is being ran for the first time. Try adding some messages with $$ooc add […]";
  }
  return utils.unping(tmp);
}

export {
  getRandomMessage ,
  formatRandomMessage ,
  formatMessageWithMsg ,
  dataWithAddedMessage ,
  dataWithRemovedMessageById ,
  updatePinnedDataWith ,
  getMessageWithId ,
  getMaxIdInData ,
  getLastMessage ,
  noPinnedMessages ,
  main ,
}
/* No side effect */
