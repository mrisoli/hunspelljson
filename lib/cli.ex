defmodule HunspellJson.CLI do
  @moduledoc """
  CLI module to output the json file
  """

  @doc """
  entry point for cli arguments
  using a single language string and no path(current path is considered)
  """
  def main([lang_str]) do
    load_files(lang_str <> ".aff", lang_str <> ".dic")
  end

  @doc """
  with both file paths included
  """
  def main([aff_path, dic_path]) do
    load_files(aff_path, dic_path)
  end

  @doc """
  with no input data
  """
  def main([]) do
    IO.puts("please provide a language string or .aff and .dic file paths")
  end

  defp load_files(aff_path, dic_path) do
    with {:ok, aff_contents} <- File.read(aff_path),
         {:ok, dic_contents} <- File.read(dic_path)
    do
      IO.puts("parsing " <> aff_path)
      IO.puts("parsing " <> dic_path)
      HunspellJson.parse(aff_contents, dic_contents)
    else
      {:error, reason} -> IO.puts(reason)
    end
  end
end
