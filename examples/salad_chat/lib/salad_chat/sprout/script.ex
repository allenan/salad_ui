defmodule SaladChat.Sprout.Script do
  @moduledoc """
  Sprout's canned brain. Picks a reasoning blurb, a search query and an answer
  for a question. No model involved: the point is to show the trace and
  streaming UI.
  """

  alias SaladChat.Chat.Search

  @plans [
    %{
      match: ~w(webhook retry retries backoff),
      query: "webhook retries backoff",
      reasoning:
        "The question is about a decision, so the answer is probably in an engineering thread. " <>
          "I'll search for webhook retries and backoff, then read the replies for the outcome.",
      answer:
        "The team agreed to use **exponential backoff with jitter** for webhook retries: a 500 ms base, " <>
          "capped at 60 s. Retries stop after **8 attempts**, then the event goes to the dead-letter queue. " <>
          "Leo is adding a `max_attempts` option to the backoff module."
    },
    %{
      match: ~w(onboarding redesign flow),
      query: "onboarding flow steps",
      reasoning:
        "Onboarding work lives in #design. I'll look for the redesign posts and the feedback thread " <>
          "to find what changed and why.",
      answer:
        "Here's the short version:\n- Onboarding goes from **7 steps to 4**.\n" <>
          "- The workspace avatar and invite steps were dropped; invites now come **after the first message**.\n" <>
          "- Visual direction: softer greens, more whitespace, playful but not childish illustrations.\n" <>
          "- The next review is at Friday's design crit."
    },
    %{
      match: ~w(freeze deploy deploys release),
      query: "deploy freeze",
      reasoning:
        "Deploy schedules are announced in #engineering. I'll search for the freeze announcement " <>
          "and any recent deploys.",
      answer:
        "The **deploy freeze starts Friday at 6pm** for the holiday weekend. Anything risky should land " <>
          "by Thursday. Leo deployed **v2.15** to production earlier today."
    },
    %{
      match: ~w(index dashboard slow latency query),
      query: "index dashboard events",
      reasoning:
        "Performance work on the dashboard was discussed with Inês. I'll search for the index and " <>
          "the numbers that came after it.",
      answer:
        "Inês added a partial index on `events (account_id, inserted_at DESC)`, built `CONCURRENTLY` " <>
          "during the quiet window. It took about 4 minutes and the dashboard's **p95 dropped from 1.8 s to 140 ms**."
    },
    %{
      match: ~w(offsite trip),
      query: "offsite schedule dietary",
      reasoning:
        "The offsite was announced in #general. I'll find the announcement and its attachments.",
      answer:
        "The offsite is **in two weeks**. Priya shared the map and schedule in #general, and asked " <>
          "everyone to add **dietary preferences by Wednesday**."
    },
    %{
      match: ~w(incident outage postmortem post-mortem queue),
      query: "queue incident post-mortem",
      reasoning:
        "Incidents get a post-mortem in #engineering. I'll search for the queue incident write-up.",
      answer:
        "Tuesday's queue incident happened because **one tenant enqueued 2M jobs** and there were no " <>
          "per-tenant limits. Leo wrote the post-mortem; the fix (per-tenant limits) is in review."
    }
  ]

  @doc """
  The plan for `question`: `%{query, reasoning, answer}`. `answer` is `nil`
  for questions without a canned answer; `answer_from_results/2` builds one.
  """
  def plan(question) do
    text = String.downcase(question)

    case Enum.find(@plans, fn plan -> Enum.any?(plan.match, &String.contains?(text, &1)) end) do
      nil ->
        query = question |> Search.terms() |> Enum.take(3) |> Enum.join(" ")
        query = if query == "", do: "recent updates", else: query

        %{
          query: query,
          reasoning:
            "I don't have a note on this yet, so I'll search the workspace for \"#{query}\" " <>
              "and summarize what comes back.",
          answer: nil
        }

      plan ->
        Map.take(plan, [:query, :reasoning, :answer])
    end
  end

  @doc "A generic answer built from search results."
  def answer_from_results(query, []),
    do:
      "I searched for \"#{query}\" but couldn't find anything in the workspace. " <>
        "Try different words, or ask in #general."

  def answer_from_results(query, results) do
    bullets = Enum.map_join(results, "\n", fn r -> "- #{r.excerpt} (#{r.where})" end)
    "Here's what I found for \"#{query}\":\n" <> bullets
  end

  @doc "Splits an answer into the chunks streamed one at a time."
  def tokens(answer) do
    Regex.split(~r/(?<=\s)/u, answer, trim: true)
  end
end
