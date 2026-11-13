defmodule SaladChat.Activity.Lines do
  @moduledoc """
  What the simulated Greenhouse people say. `{@}` in a line is replaced with
  a mention of another member of the conversation (see `SaladChat.Activity`).
  """

  @channels %{
    "general" => [
      "Morning all ☀️",
      "Reminder: demo day is Thursday at 4pm, sign-up sheet is pinned.",
      "Quarterly planning doc is open for comments until Friday.",
      "Welcome back {@}! How was the trip?",
      "The all-hands recording is up in the usual folder.",
      "Who's around for a quick sync on the launch checklist?",
      "Office wifi is getting swapped tonight, expect a blip around 7pm.",
      "Huge thanks to {@} for jumping on the customer escalation yesterday 🙏",
      "Reminder to submit expenses before the end of the month.",
      "New starter next Monday! Say hi when you see them 👋",
      "Moving the retro to Wednesday, calendar invite updated.",
      "We hit 1,000 workspaces this week 🎉",
      "Anyone know where the spare HDMI adapters went?",
      "I'll be out Friday afternoon, {@} is covering for me.",
      "Customer NPS came back at 61, up from 54 last quarter.",
      "Lunch and learn tomorrow: {@} on writing better PR descriptions.",
      "Roadmap for next quarter is in the wiki, feedback welcome.",
      "Fire drill at 11 today, apparently a real one this time.",
      "Small reminder: please update your status if you're heads down.",
      "Shipped the new onboarding emails 📬"
    ],
    "engineering" => [
      "Deploying the queue worker changes now 🚀",
      "Deploy is out, watching the dashboards.",
      "Flaky test in `chat_live_test.exs` again. {@} any ideas?",
      "CI is green again after the cache bust 🟢",
      "PR is up for the retry backoff, small one: 40 lines.",
      "Who's on call tonight? Want to hand over the migration.",
      "Bumped Phoenix and LiveView on main, no surprises so far.",
      "Memory on the worker nodes looks flat after the ETS change.",
      "{@} could you review the presence PR when you get a sec?",
      "Rolled back the search index tweak, results got worse.",
      "Note to self: never `rm -rf` in the wrong terminal tab.",
      "Postgres vacuum finished, bloat is down 30%.",
      "Pairing on the websocket reconnect bug after lunch if anyone wants in.",
      "TIL `Process.send_after/3` returns a ref you can cancel. Using it for the debounce.",
      "The staging cert renews tomorrow, nothing to do.",
      "Added a telemetry event for slow renders, dashboards later today.",
      "Release notes draft is in the doc, {@} please sanity check the API bits.",
      "Benchmarks: the new message list renders 2x faster with streams.",
      "Alert fired for disk on worker-3, cleaned up old logs.",
      "Feature flag for threads v2 is on for internal users.",
      "Anyone else seeing `:timeout` from the export job? Looking now."
    ],
    "design" => [
      "Posted a new version of the composer, feedback welcome 🎨",
      "{@} the hover card spacing feels off at small sizes, can you take a look?",
      "Trying a quieter border on the sidebar, screenshots in the file.",
      "Usability test notes are in: people loved the quick switcher.",
      "Dark mode contrast pass done for the thread pane 🌙",
      "Exploring an empty state illustration for new channels.",
      "Should reactions show a count of 1 or just the emoji?",
      "Updated the icon set to match the new stroke width.",
      "Crit moved to 3pm today, same link.",
      "Can someone sanity check the focus rings on Safari?",
      "Motion spec for the toasts: 150ms in, 100ms out.",
      "{@} love the new avatar colors, very calm ✨",
      "The settings dialog now fits on a phone without scrolling.",
      "Reworked the typing indicator dots, less bouncy.",
      "Research synthesis is up: three themes, two surprises.",
      "Mobile sidebar sheet feels great with the new easing.",
      "We need a clearer pressed state for toggle buttons.",
      "Font size preference is wired up in the prototype.",
      "Shared a Loom of the new onboarding flow.",
      "Badge colors are now tokens, no more hardcoded hex."
    ],
    "random" => [
      "Coffee run, anyone? ☕",
      "The office plant got a new pot and looks very proud 🌱",
      "Recommend me a podcast for a long train ride 🚆",
      "{@} the banana bread was incredible, recipe please",
      "Is it just me or is it freezing in the meeting room?",
      "Rain again 🌧️ good day to stay in and write docs.",
      "Spotted a fox outside the office this morning 🦊",
      "Ramen for lunch? 🍜",
      "Finished the sci-fi book {@} recommended, wow.",
      "Who's in for board games on Thursday? 🎲",
      "My cat walked across the keyboard mid-standup 🐈",
      "Hot take: tabs are better than spaces.",
      "There's cake in the kitchen 🎂 first come first served",
      "Running club meets at 7am tomorrow, all paces welcome 🏃",
      "Best sandwich place nearby? Asking for a friend.",
      "Sunset from the roof today was unreal 🌇",
      "{@} are you still selling that bike?",
      "Friday playlist thread, drop your song of the week 🎧",
      "New pastry shop opened on the corner, verdict: excellent 🥐",
      "TIL octopuses taste with their arms 🐙"
    ]
  }

  @replies [
    "+1",
    "Agreed 👍",
    "On it.",
    "Nice, thanks for the heads up!",
    "Makes sense to me.",
    "Can you share the link?",
    "{@} might know more about this one.",
    "I can take a look after lunch.",
    "Good call.",
    "Let's do it 🚀",
    "Same here, saw it this morning.",
    "Love this ✨",
    "Hmm, not sure, let's talk at standup.",
    "Done ✅",
    "Thanks {@}!",
    "Ha, classic 😂",
    "Can we add this to the agenda?",
    "Looks good to me, ship it.",
    "I'll write it up in the doc.",
    "Following 👀",
    "Count me in!",
    "Fixed in the latest build, can you check?",
    "That's a great point.",
    "Pinging {@} for visibility."
  ]

  @dms [
    "Hey, got 5 minutes for a quick call?",
    "Thanks for the help earlier 🙏",
    "Did you see the latest version of the doc?",
    "Can you send me the link from the meeting?",
    "Lunch today?",
    "Quick question about the deploy when you have a sec.",
    "Running a few minutes late to our 1:1.",
    "Nice work on the demo yesterday!",
    "Are we still on for pairing this afternoon?",
    "Just left you a few comments on the PR.",
    "Could you cover my standup update tomorrow?",
    "Saw this and thought of you 😄",
    "Want to grab coffee later? ☕",
    "No rush, but can you look at the ticket I assigned you?"
  ]

  @doc "The public channels with something to say, by id."
  def channel_ids, do: Map.keys(@channels)

  @doc "Top-level lines for a channel (`[]` for unknown channels)."
  def channel(id), do: Map.get(@channels, id, [])

  def replies, do: @replies

  def dms, do: @dms

  @doc "Reaction emoji, all of them already used in the seed history."
  def emoji, do: ~w(👍 🎉 🚀 👀 ✅ 🔥 😂 🙌 🙏 ✨ 😍 ☕ 🌱)
end
