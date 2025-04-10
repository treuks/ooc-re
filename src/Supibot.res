let prefix = "OOC_MSGS"

module ChannelCustomData = {
    type oocMessage = { id: int, text: string, date: string, addedBy: string }
    type oocData = { currentId: int, messages: array<oocMessage> }

    @scope("channelCustomData") @val @return(nullable)
    external get: string => option<'a> = "get"

    @scope("channelCustomData") @val 
    external set: (string, 'a) => unit = "set"

    type oocError =
        | NoMessages
        // | CorruptData

    let getOoc = () : result<oocData, oocError> => {
        
        let data = get(prefix)

        let cdata = data->Option.getOr({ currentId: 0, messages: []})

        let result = {
            if cdata.messages->Array.length == 0 {
                Error(NoMessages)
            } else {
                Ok(cdata)
            }
        }

        result
    }
}

module Utils = {

    type searchParams = { ignoreCase: bool, fullResult: option<bool> }

    type closestStringDescriptor = {
        @as("string") searchString: string,
        original: string,
        index: int,
        score: float,
        includes: bool,
    };

    @scope("utils") @val
    external unping: string => string = "unping"

    @scope("utils") @val @return(nullable)
    external selectClosestString: (
        string, 
        array<string>, 
        @as(json`{ ignoreCase: true, descriptor: true }`) _,
        ) => option<closestStringDescriptor> = "selectClosestString"
}

@val
external executor : string = "executor"