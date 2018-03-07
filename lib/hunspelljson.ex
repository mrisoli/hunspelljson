defmodule HunspellJson do
  @moduledoc """
  Generate a json file from a hunspell affix and dictionary file
  """

  alias HunspellJson.AffParser

  @doc """
  parse generates the json from the affix and dictionary contents
  """
  def parse(aff_contents, dic_contents) do
    aff_contents
    |> AffParser.parse
    # |> Poison.encode!
    # |> (&File.write("output.json", &1)).()
  end
end
