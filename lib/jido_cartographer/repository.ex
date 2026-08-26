defmodule JidoCartographer.Repository do
  @owner ~r/\A[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})\z/
  @repo ~r/\A[A-Za-z0-9._-]{1,100}\z/
  @ref ~r/\A[A-Za-z0-9._\/-]{1,200}\z/

  def parse(url, ref \\ nil)

  def parse(url, ref) when is_binary(url) do
    with {:ok, uri} <- URI.new(String.trim(url)),
         :ok <- validate_uri(uri),
         {:ok, owner, repo} <- parse_path(uri.path),
         {:ok, clean_ref} <- validate_ref(ref) do
      {:ok,
       %{owner: owner, repo: repo, ref: clean_ref, url: "https://github.com/#{owner}/#{repo}"}}
    end
  end

  def parse(_, _), do: {:error, "repository URL must be a string"}

  def archive_url(%{owner: owner, repo: repo, ref: ref}) do
    encoded_ref = URI.encode(ref, &URI.char_unreserved?/1)
    "https://codeload.github.com/#{owner}/#{repo}/tar.gz/#{encoded_ref}"
  end

  defp validate_uri(%URI{
         scheme: "https",
         host: "github.com",
         userinfo: nil,
         port: port,
         query: nil,
         fragment: nil
       })
       when port in [nil, 443],
       do: :ok

  defp validate_uri(_),
    do: {:error, "only credential-free https://github.com repository URLs are allowed"}

  defp parse_path(path) do
    case path |> String.trim("/") |> String.split("/") do
      [owner, repo] -> validate_owner_repo(owner, String.trim_trailing(repo, ".git"))
      _ -> {:error, "repository URL must have exactly an owner and repository"}
    end
  end

  defp validate_owner_repo(owner, repo) do
    if Regex.match?(@owner, owner) and Regex.match?(@repo, repo) and repo not in [".", ".."] do
      {:ok, owner, repo}
    else
      {:error, "invalid GitHub owner or repository name"}
    end
  end

  defp validate_ref(nil), do: {:ok, "HEAD"}
  defp validate_ref(""), do: {:ok, "HEAD"}

  defp validate_ref(ref) when is_binary(ref) do
    clean = String.trim(ref)

    if Regex.match?(@ref, clean) and not String.contains?(clean, ["..", "//"]) and
         not String.starts_with?(clean, "/") do
      {:ok, clean}
    else
      {:error, "invalid Git ref"}
    end
  end

  defp validate_ref(_), do: {:error, "Git ref must be a string"}
end
