defmodule HunspellJson.RuleCodeParser do
  @moduledoc """
  parses rule codes based on addition characters
  """

  def parse(_flag_set, []), do: []

  def parse(flag_set, text_codes) do
    case flag_set["FLAG"] do
      "long" -> Enum.chunk_every(String.graphemes(text_codes),2)
      "num" -> String.split(text_codes, ",")
      nil -> String.graphemes(text_codes)
    end
  end
end
