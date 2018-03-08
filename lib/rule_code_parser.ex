defmodule HunspellJson.RuleCodeParser do
  @moduledoc """
  parses rule codes based on addition characters
  """

  def parse(_flag_set, nil), do: []

  def parse(flag_set, text_codes), do: read_flag(text_codes, flag_set["FLAG"])

  defp read_flag(text_codes, "long") do
    Enum.chunk_every(String.graphemes(text_codes), 2)
  end

  defp read_flag(text_codes, "num"), do: String.split(text_codes, ",")
  defp read_flag(text_codes, nil), do: String.graphemes(text_codes)
end
