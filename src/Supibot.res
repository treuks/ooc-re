let prefix = "OOC_MSGS"

module ChannelCustomData = {
  type oocMessage = {id: int, text: string, date: string, addedBy: string}
  type oocData = {currentId: int, messages: array<oocMessage>}

  @scope("channelCustomData") @val @return(nullable)
  external get: string => option<'a> = "get"

  @scope("channelCustomData") @val
  external set: (string, 'a) => unit = "set"

  type oocError = NoMessages
  // | CorruptData

  let getOoc = (): result<oocData, oocError> => {
    let data = get(prefix)

    let cdata = data->Option.getOr({currentId: 0, messages: []})

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
  type searchParams = {ignoreCase: bool, fullResult: option<bool>}

  type closestStringDescriptor = {
    @as("string") searchString: string,
    original: string,
    index: int,
    score: float,
    includes: bool,
  }

  @scope("utils") @val
  external unping: string => string = "unping"

  @scope("utils") @val @return(nullable)
  external selectOneClosestString: (
    string,
    array<string>,
    @as(json`{ ignoreCase: true, descriptor: true }`) _,
  ) => option<closestStringDescriptor> = "selectClosestString"

  @scope("utils") @val @return(nullable)
  external selectAllClosestStrings: (
    string,
    array<string>,
    @as(json`{ ignoreCase: true, fullResult: true }`) _,
  ) => option<array<closestStringDescriptor>> = "selectClosestString"

  @scope("utils") @val
  external random: (int, int) => int = "random"

  type parameterTypeKeys =
    | @as("string") String
    | @as("number") Number
    | @as("boolean") Boolean

  @unboxed
  type parameterType =
    | String(string)
    | Number(float)
    | Boolean(bool)

  @tag("success")
  type parseResult =
    | @as(true) Success({parameters: Js.Dict.t<parameterType>})
    | @as(false) Failure({reply: string})

  type parameterDefinition = {
    name: string,
    @as("type") type_: parameterTypeKeys,
  }

  @scope("utils") @val
  external parseParametersFromArguments: (
    array<parameterDefinition>,
    array<string>,
  ) => parseResult = "parseParametersFromArguments"
}

@val
external executor: string = "executor"
