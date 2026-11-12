defmodule SaladChat.Chat.Seed do
  @moduledoc """
  Deterministic seed data for the "Greenhouse" workspace: people, channels,
  DMs and about ten days of history.

  The content is fixed; only the timestamps are relative to `now`, so the
  history always ends "just now".
  """

  alias SaladChat.Chat.{Channel, Message, Search, User}
  alias SaladChat.Sprout.Script

  @humans ~w(maya leo priya sam ines jonah kai)

  def humans, do: @humans

  @doc "Builds every record. Returns `%{users, channels, messages, reads}`."
  def build(%DateTime{} = now) do
    now = now |> DateTime.truncate(:second) |> Map.put(:second, 0)
    channels = channels(now)

    entries =
      curated()
      |> Enum.with_index()
      |> Enum.flat_map(fn {entry, key} -> expand(entry, key, now) end)
      |> Kernel.++(filler(now))
      |> Enum.sort_by(&{DateTime.to_unix(&1.at), &1.order})

    messages = assign_ids(entries)
    messages = link_threads(messages)
    messages = attach_bot_traces(messages)

    %{
      users: users(),
      channels: channels,
      messages: messages,
      reads: reads(messages, channels, now)
    }
  end

  ## People

  def users do
    [
      user("maya", "Maya Okafor", "Product Designer", "berlin", "bg-rose-500",
        status_text: "Prototyping onboarding v3",
        bio: "Designs calm software. Collects houseplants and fonts."
      ),
      user("leo", "Leo Brandt", "Staff Engineer", "berlin", "bg-sky-600",
        status_text: "On call this week",
        bio: "Backend, queues, and the occasional pager. Tabs person."
      ),
      user("priya", "Priya Raman", "Engineering Manager", "london", "bg-violet-600",
        bio: "Keeps the trains running. Ask me about planning."
      ),
      user("sam", "Sam Whitaker", "Frontend Engineer", "eastern", "bg-amber-500",
        status_text: "Composer PR in review",
        bio: "LiveView, CSS, and keyboard shortcuts."
      ),
      user("ines", "Inês Carvalho", "Data Engineer", "london", "bg-teal-600",
        bio: "Pipelines, Postgres and a lot of coffee."
      ),
      user("jonah", "Jonah Pike", "Developer Advocate", "pacific", "bg-orange-500",
        status: "away",
        status_text: "At ElixirConf",
        bio: "Talks, docs and demos."
      ),
      user("kai", "Kai Nakamura", "Product Manager", "tokyo", "bg-indigo-600",
        avatar: nil,
        bio: "Turning customer calls into roadmaps."
      ),
      %User{
        handle: "sprout",
        name: "Sprout",
        title: "AI assistant",
        bio: "I search the workspace, summarize threads and set reminders.",
        avatar: "/images/seed/avatars/sprout.svg",
        color: "bg-emerald-600",
        timezone: "london",
        bot?: true
      }
    ]
  end

  defp user(handle, name, title, tz, color, opts) do
    %User{
      handle: handle,
      name: name,
      title: title,
      timezone: tz,
      color: color,
      avatar: Keyword.get(opts, :avatar, "/images/seed/avatars/#{handle}.svg"),
      status: Keyword.get(opts, :status, "active"),
      status_text: Keyword.get(opts, :status_text),
      bio: Keyword.get(opts, :bio, "")
    }
  end

  ## Channels

  defp channels(now) do
    created = DateTime.add(now, -40 * 86_400, :second)
    everyone = @humans ++ ["sprout"]

    [
      %Channel{
        id: "general",
        name: "general",
        topic: "Ship small, ship often. Demo day is Thursday 4pm.",
        description: "Company-wide announcements and work-based matters.",
        members: everyone,
        created_by: "priya",
        inserted_at: created
      },
      %Channel{
        id: "engineering",
        name: "engineering",
        topic: "Deploys Tue/Thu · on call: @leo",
        description: "Backend, frontend, infrastructure and everything in between.",
        members: ~w(leo priya sam ines jonah sprout),
        created_by: "leo",
        inserted_at: created
      },
      %Channel{
        id: "design",
        name: "design",
        topic: "Design crit Fridays 2pm · Figma links welcome",
        description: "Product design, research and the design system.",
        members: ~w(maya sam kai priya sprout),
        created_by: "maya",
        inserted_at: created
      },
      %Channel{
        id: "random",
        name: "random",
        topic: "Non-work banter and water cooler conversation",
        description: "Books, lunch, pets and hot takes.",
        members: everyone,
        created_by: "jonah",
        inserted_at: created
      },
      %Channel{
        id: "ai-assistant",
        name: "ai-assistant",
        topic: "Ask @sprout anything. It searches the workspace and shows its work.",
        description: "Talk to Sprout, the workspace's AI assistant.",
        members: everyone,
        created_by: "priya",
        inserted_at: created
      }
    ] ++
      Enum.map([~w(leo maya), ~w(priya sam), ~w(jonah kai), ~w(ines leo), ~w(maya sprout)], fn [
                                                                                                 a,
                                                                                                 b
                                                                                               ] ->
        %Channel{
          id: Channel.dm_id(a, b),
          name: Channel.dm_id(a, b),
          kind: :dm,
          members: Enum.sort([a, b]),
          created_by: a,
          inserted_at: created
        }
      end)
  end

  ## Curated history

  # {when, channel, user, body, opts}
  # when: {days_ago, "HH:MM"} (UTC) or {:ago, minutes}
  # opts: replies: [{minutes_after, user, body} | {minutes_after, user, body, opts}],
  #       react: [{emoji, users | :all}], pinned: handle, edited: true,
  #       files: [file], bot: question
  defp curated do
    [
      # #general
      {{9, "08:02"}, "general", "priya",
       "Morning all ☀️ Quick reminder that the **Q4 planning doc** is open for comments until Friday. Please add your team's top three bets.",
       pinned: "priya",
       react: [{"👀", ~w(leo sam kai)}, {"✅", ~w(maya)}],
       replies: [
         {12, "kai", "Added product's three. Happy to pair on sizing with anyone."},
         {40, "leo", "Platform bets are in. Spoiler: it's mostly paying down the job queue 😅"}
       ]},
      {{9, "09:15"}, "general", "jonah",
       "I'll be at ElixirConf next week giving a talk on LiveView streams. The slides draft is in the shared drive, feedback very welcome 🙏",
       react: [{"🎉", ~w(maya priya ines sam)}]},
      {{8, "10:30"}, "general", "kai",
       "Release notes for **v2.14** are up. Big one: threaded replies are now GA 🎉",
       files: [file("release-notes.md")], react: [{"🚀", ~w(leo sam maya priya)}]},
      {{7, "12:01"}, "general", "priya",
       "Lunch & learn today at 1pm: @ines is walking us through the new analytics pipeline. Bring questions!",
       react: [{"🍕", ~w(sam jonah)}]},
      {{6, "16:45"}, "general", "maya",
       "Office plants update: the monstera has a new leaf. That is all. 🌿",
       react: [{"🌱", ~w(leo ines kai jonah priya)}, {"😂", ~w(sam)}]},
      {{5, "09:00"}, "general", "priya",
       "Please welcome @sprout, our new AI assistant! Ask it anything in #ai-assistant. It can search our message history and summarize threads.",
       pinned: "priya",
       react: [{"👋", :all}],
       replies: [
         {3, "sprout",
          "Thanks for the warm welcome! 🌱 I'm happy to find things, summarize long threads or draft replies. Try me in #ai-assistant."}
       ]},
      {{3, "11:20"}, "general", "kai",
       "Heads up: the customer advisory board is Thursday. If you want to sit in, ping me and I'll share the dial-in."},
      {{1, "09:05"}, "general", "priya",
       "Reminder: the offsite is in two weeks 🏕️ Map and schedule attached. Please fill in dietary preferences by Wednesday.",
       files: [image("offsite-map.svg", "Offsite map")], react: [{"🙌", ~w(maya ines jonah)}]},
      {{:ago, 95}, "general", "sam",
       "Anyone else seeing the CI queue backed up? My PR has been waiting 20 minutes.",
       replies: [
         {3, "leo", "Yep, one of the runners died. Restarting it now."},
         {11, "leo", "Should be draining now 👍"}
       ]},
      {{:ago, 25}, "general", "kai",
       "@here Demo day moved to **Thursday 4pm** so we can include the new composer. Sorry for the shuffle!",
       react: [{"👍", ~w(sam ines)}]},

      # #engineering
      {{9, "10:12"}, "engineering", "leo",
       """
       Proposal: switch the webhook retries to exponential backoff with jitter. Something like:
       ```elixir
       defmodule Greenhouse.Webhooks.Backoff do
         @base_ms 500
         @max_ms 60_000

         def delay(attempt) when attempt >= 0 do
           exp = min(@max_ms, @base_ms * Integer.pow(2, attempt))
           div(exp, 2) + :rand.uniform(div(exp, 2))
         end
       end
       ```
       Thoughts?\
       """,
       pinned: "leo",
       react: [{"👍", ~w(sam ines priya)}, {"🧠", ~w(jonah)}],
       replies: [
         {20, "ines",
          "Love it. Can we cap total retries at 8 attempts? After that we should dead-letter."},
         {35, "leo", "Yes, I'll add a `max_attempts` option and push to the DLQ."},
         {60, "sam", "Ship it 🚢"}
       ]},
      {{8, "14:40"}, "engineering", "ines",
       """
       The events table is getting slow for the dashboard queries. This index should help:
       ```sql
       CREATE INDEX CONCURRENTLY events_account_inserted_idx
         ON events (account_id, inserted_at DESC)
         WHERE deleted_at IS NULL;
       ```
       Running it tonight during the quiet window.\
       """,
       files: [file("migration.sql")],
       react: [{"✅", ~w(leo priya)}],
       replies: [
         {15, "leo", "Make sure to `SET lock_timeout` first, just in case."},
         {480, "ines",
          "Good call, added. Index built in 4m12s and the dashboard p95 dropped from 1.8s to 140ms 📉",
          files: [image("latency-chart.svg", "Dashboard latency before and after")]}
       ]},
      {{7, "11:05"}, "engineering", "sam",
       """
       Small JS helper I keep copy-pasting. Should we put it in the shared hooks?
       ```js
       export const debounce = (fn, wait = 200) => {
         let timer
         return (...args) => {
           clearTimeout(timer)
           timer = setTimeout(() => fn(...args), wait)
         }
       }
       ```\
       """,
       react: [{"👍", ~w(leo jonah)}],
       replies: [
         {9, "jonah", "Yes please. Add a `throttle` while you're there?"},
         {14, "sam", "On it."}
       ]},
      {{6, "09:30"}, "engineering", "priya",
       "Deploy freeze starts **Friday 6pm** for the holiday weekend. Anything risky should land by Thursday.",
       pinned: "priya"},
      {{5, "15:10"}, "engineering", "leo",
       "Post-mortem for Tuesday's queue incident is up. TL;DR: a single tenant enqueued 2M jobs and we didn't have per-tenant limits. The fix is in review.",
       react: [{"🙏", ~w(priya ines sam)}],
       replies: [
         {25, "priya",
          "Thanks for the thorough write-up @leo. Let's go through it in Thursday's eng sync."}
       ]},
      {{4, "13:22"}, "engineering", "sam",
       "PR for the new composer is up: Enter to send, Shift+Enter for a newline, drag & drop uploads. Would love eyes from @maya on the empty states.",
       edited: true, react: [{"👀", ~w(maya)}]},
      {{2, "10:00"}, "engineering", "ines",
       "The analytics pipeline is now on the new cluster. Backfill finished overnight: 41M rows, zero errors 🎉",
       react: [{"🎉", ~w(leo priya kai sam)}]},
      {{1, "16:30"}, "engineering", "leo",
       "Who's up for pairing on the presence tracker tomorrow? It still flaps when a node restarts.",
       replies: [{4, "sam", "Me! 10am?"}, {6, "leo", "10am works"}]},
      {{:ago, 140}, "engineering", "jonah",
       """
       Writing a blog post on how we use LiveView streams for the message list. Can someone sanity-check this?
       ```elixir
       def handle_info({:message_created, message}, socket) do
         {:noreply, stream_insert(socket, :messages, message)}
       end
       ```\
       """,
       replies: [{12, "leo", "Looks right. Mention `limit:` so the DOM doesn't grow forever."}]},
      {{:ago, 50}, "engineering", "leo", "Deploying v2.15 to production now 🚀 cc @priya",
       react: [{"🚀", ~w(sam ines)}]},

      # #design
      {{9, "11:00"}, "design", "maya",
       "Moodboard for the onboarding refresh. Leaning into softer greens and more whitespace.",
       files: [image("moodboard.svg", "Onboarding moodboard")],
       pinned: "maya",
       react: [{"😍", ~w(sam kai jonah)}, {"🌿", ~w(ines)}],
       replies: [
         {18, "kai", "This is gorgeous. Can we keep the illustrations playful but not childish?"},
         {26, "maya", "Exactly the brief. Round 2 on Friday."}
       ]},
      {{8, "15:20"}, "design", "sam",
       "Do we have a token for the muted border in dark mode? I keep hardcoding `zinc-800`.",
       replies: [
         {7, "maya", "Use `border-border`, it switches automatically. I'll add it to the docs."}
       ]},
      {{6, "14:00"}, "design", "maya",
       "New onboarding flow: 4 steps instead of 7. Notes in the thread.",
       files: [image("onboarding-flow.svg", "Onboarding flow, 4 steps")],
       react: [{"🔥", ~w(priya kai leo)}],
       replies: [
         {10, "priya", "Love the cut from 7 to 4. What did we drop?"},
         {16, "maya",
          "The workspace avatar and the invite step. Invites now come after the first message."},
         {30, "kai", "Big +1 on deferring invites."}
       ]},
      {{4, "16:00"}, "design", "kai",
       "Design crit tomorrow at 2pm. Agenda: empty states, the new composer, and the AI trace UI."},
      {{2, "10:45"}, "design", "maya", "Logo concepts for @sprout 🌱 Which direction?",
       files: [image("sprout-logo.svg", "Sprout logo concepts")],
       react: [{"1️⃣", ~w(sam leo)}, {"2️⃣", ~w(kai priya)}]},
      {{:ago, 200}, "design", "maya",
       "Updated the empty states. The illustrations are SVG now, so they follow dark mode.",
       edited: true, react: [{"✨", ~w(sam)}]},

      # #random
      {{9, "17:30"}, "random", "sam", "What's everyone reading? I just started *The Overstory* 🌳",
       replies: [
         {6, "ines", "Piranesi! Can't recommend it enough."},
         {21, "jonah", "Re-reading Designing Data-Intensive Applications. Yes, for fun."}
       ]},
      {{7, "13:13"}, "random", "jonah", "PSA: the coffee machine on 3 is fixed ☕",
       react: [{"☕", ~w(leo priya maya kai sam)}]},
      {{5, "18:02"}, "random", "ines", "Sunset from the office roof today",
       files: [image("sunset.svg", "Sunset over the city")], react: [{"😍", ~w(maya priya kai)}]},
      {{3, "12:30"}, "random", "leo", "Hot take: tabs > spaces. Fight me.",
       react: [{"😂", ~w(sam maya)}, {"🔥", ~w(jonah)}],
       replies: [
         {2, "sam", "`mix format` has entered the chat"},
         {5, "ines", "The formatter decides. We are merely its servants."}
       ]},
      {{1, "12:00"}, "random", "kai", "Team lunch Friday? Thinking ramen 🍜",
       react: [{"🍜", :all}]},
      {{:ago, 300}, "random", "maya",
       "My cat just walked across the keyboard and filed a ticket. Honestly better written than mine.",
       react: [{"😂", ~w(leo sam ines kai)}]},

      # #ai-assistant
      {{5, "09:30"}, "ai-assistant", "sprout",
       "Hi! I'm **Sprout** 🌱 Ask me things like:\n- What did we decide about webhook retries?\n- Summarize the onboarding redesign\n- When is the deploy freeze?\nI search the workspace and show my work.",
       pinned: "priya"},
      {{4, "10:05"}, "ai-assistant", "kai", "@sprout what did we decide about webhook retries?"},
      {{4, "10:06"}, "ai-assistant", "sprout", "",
       bot: "what did we decide about webhook retries?"},
      {{2, "14:30"}, "ai-assistant", "priya", "@sprout summarize the onboarding redesign"},
      {{2, "14:31"}, "ai-assistant", "sprout", "", bot: "summarize the onboarding redesign"},

      # DMs
      {{3, "15:00"}, "dm-leo-maya", "maya",
       "Got a sec to look at the composer spacing? Something feels off at 320px."},
      {{3, "15:04"}, "dm-leo-maya", "leo", "Yeah, the attach button wraps. I'll push a fix."},
      {{3, "15:05"}, "dm-leo-maya", "maya", "You're the best 🙌"},
      {{:ago, 70}, "dm-leo-maya", "leo", "Fix is on staging if you want to check"},
      {{2, "17:00"}, "dm-priya-sam", "priya",
       "Great work on the composer PR this week. Want to demo it Thursday?"},
      {{2, "17:12"}, "dm-priya-sam", "sam", "Absolutely! I'll prep a 5-minute walkthrough."},
      {{1, "10:00"}, "dm-jonah-kai", "kai", "Can you draft the changelog blurb for threads?"},
      {{1, "14:20"}, "dm-jonah-kai", "jonah", "Here you go. Edit freely!",
       files: [file("release-notes.md")]},
      {{4, "09:00"}, "dm-ines-leo", "ines", "Do you have the numbers from before the index?"},
      {{4, "09:30"}, "dm-ines-leo", "leo", "Here's the raw export",
       files: [file("q4-metrics.csv")]},
      {{5, "09:31"}, "dm-maya-sprout", "sprout",
       "Hi Maya! 👋 I'm Sprout. Message me anytime: I can search the workspace, summarize threads and remind you about things."}
    ]
  end

  defp expand({when_, channel, user, body}, key, now),
    do: expand({when_, channel, user, body, []}, key, now)

  defp expand({when_, channel, user, body, opts}, key, now) do
    at = at(when_, now)

    parent = %{
      key: key,
      parent_key: nil,
      order: 0,
      at: at,
      channel: channel,
      user: user,
      body: body,
      opts: opts
    }

    replies =
      opts
      |> Keyword.get(:replies, [])
      |> Enum.with_index(1)
      |> Enum.map(fn {reply, i} ->
        {mins, r_user, r_body, r_opts} =
          case reply do
            {m, u, b} -> {m, u, b, []}
            {m, u, b, o} -> {m, u, b, o}
          end

        %{
          key: {key, i},
          parent_key: key,
          order: i,
          at: clamp(DateTime.add(at, mins * 60, :second), now),
          channel: channel,
          user: r_user,
          body: r_body,
          opts: r_opts
        }
      end)

    [parent | replies]
  end

  defp at({:ago, minutes}, now), do: DateTime.add(now, -minutes * 60, :second)

  defp at({days, hhmm}, now) do
    date = now |> DateTime.to_date() |> Date.add(-days)
    DateTime.new!(date, Time.from_iso8601!(hhmm <> ":00"), "Etc/UTC")
  end

  defp clamp(at, now) do
    latest = DateTime.add(now, -60, :second)
    if DateTime.after?(at, latest), do: latest, else: at
  end

  ## Filler: generic chatter so the channels feel lived in

  @filler %{
    "general" => [
      "Good morning everyone! ☕",
      "Reminder to update your OKR check-ins before Friday.",
      "Thanks for the help today, team 🙏",
      "The all-hands recording is in the shared drive.",
      "Who's in the office tomorrow?",
      "Calendar invites for next week's planning are out.",
      "Friendly reminder: expense reports are due on the 30th.",
      "Happy Friday! 🎉",
      "The wifi on the 2nd floor is back.",
      "Has anyone seen the HDMI adapter from the Fern room?",
      "Shoutout to the support team for crushing the backlog this week 💪",
      "Reminder: no meetings on Wednesday afternoons.",
      "The newsletter draft is ready for review.",
      "Thanks for the birthday wishes! 🎂",
      "New hire onboarding buddies are assigned, check your inbox.",
      "Parking garage is closed tomorrow morning for maintenance."
    ],
    "engineering" => [
      "Merged the migration, rolling out behind a flag.",
      "Flaky test in `presence_test.exs` again 😩",
      "Bumped Phoenix on staging, all green so far.",
      "Can someone review #482? It's small.",
      "Heads up: rotating the staging database credentials at 3pm.",
      "p95 latency is back to normal after the cache fix.",
      "TIL `:ets.select_reverse/3` takes a limit. Handy for pagination.",
      "Dependabot opened 6 PRs overnight. Batching them now.",
      "The error tracker caught a nil in the billing worker. Fix incoming.",
      "Reminder: write the ADR before the big refactor, not after 😉",
      "Staging is a bit slow right now, a load test is running.",
      "Turned on query logging for the search endpoint for an hour.",
      "Who owns the cron for the nightly exports?",
      "Updated the runbook for the queue alerts.",
      "Reverted the font loading change, it broke Safari.",
      "Green build on main 🟢"
    ],
    "design" => [
      "Pushed new icons for the sidebar.",
      "Can we get a dark mode pass on the settings dialog?",
      "Tightened the spacing on message groups, it feels calmer.",
      "The Figma file has the new type scale.",
      "Should the unread badge be red or primary? Testing both.",
      "Loving the new avatar fallbacks.",
      "Accessibility pass: bumped muted text contrast to 4.6:1.",
      "Added hover states for reactions.",
      "Kbd hints are in for the composer.",
      "Prototype updated with the thread pane.",
      "Recorded a quick walkthrough of the new composer interactions.",
      "The skeletons now match the real message layout.",
      "Trying a softer radius on bubbles.",
      "Does anyone have the brand green hex handy?",
      "Exported the illustration set as SVG.",
      "Crit notes are in the doc."
    ],
    "random" => [
      "Anyone want to grab coffee? ☕",
      "Lunch recs near the office?",
      "This song has been on repeat all morning 🎧",
      "It's raining again 🌧️",
      "Bike to work week! Who's in? 🚲",
      "The plant on my desk is thriving, finally.",
      "Weekend plans?",
      "Just discovered the bakery around the corner. Dangerous.",
      "Movie night Thursday?",
      "Who left the excellent cookies in the kitchen? 🍪",
      "Fun fact: octopuses have three hearts.",
      "Board game recommendations for 4 people?",
      "Office dog sighting 🐕",
      "Highly recommend the new trail by the river.",
      "Who's watching the match tonight?",
      "Mondays, am I right?"
    ]
  }

  @filler_per_day %{"general" => 6, "engineering" => 7, "design" => 5, "random" => 5}
  @filler_people %{
    "general" => ~w(priya kai maya leo sam ines jonah),
    "engineering" => ~w(leo sam ines priya jonah),
    "design" => ~w(maya sam kai priya),
    "random" => ~w(sam jonah ines maya leo kai priya)
  }

  defp filler(now) do
    for {channel, per_day} <- @filler_per_day,
        day <- 9..1//-1,
        i <- 0..(per_day - 1) do
      lines = @filler[channel]
      people = @filler_people[channel]
      n = day * 7 + i * 3 + String.length(channel)
      minutes = 7 * 60 + 30 + i * div(9 * 60, per_day) + rem(n * 13, 40)
      date = now |> DateTime.to_date() |> Date.add(-day)
      at = DateTime.new!(date, Time.new!(div(minutes, 60), rem(minutes, 60), 0), "Etc/UTC")

      %{
        key: {:filler, channel, day, i},
        parent_key: nil,
        order: 0,
        at: at,
        channel: channel,
        user: Enum.at(people, rem(n, length(people))),
        body: Enum.at(lines, rem(n * 5 + i, length(lines))),
        opts: []
      }
    end
  end

  ## Assembly

  defp assign_ids(entries) do
    entries
    |> Enum.with_index(1)
    |> Enum.map(fn {e, id} ->
      opts = e.opts

      {
        e,
        %Message{
          id: id,
          channel_id: e.channel,
          user_id: e.user,
          body: e.body,
          inserted_at: e.at,
          edited_at: if(opts[:edited], do: DateTime.add(e.at, 240, :second)),
          pinned_by: opts[:pinned],
          reactions: reactions(opts[:react] || []),
          attachments: opts[:files] || [],
          bot: if(q = opts[:bot], do: %{question: q})
        }
      }
    end)
  end

  defp link_threads(pairs) do
    ids = Map.new(pairs, fn {e, m} -> {e.key, m.id} end)

    messages =
      Enum.map(pairs, fn {e, m} ->
        if e.parent_key, do: %{m | parent_id: Map.fetch!(ids, e.parent_key)}, else: m
      end)

    replies = Enum.group_by(Enum.filter(messages, & &1.parent_id), & &1.parent_id)

    Enum.map(messages, fn m ->
      case Map.get(replies, m.id) do
        nil ->
          m

        rs ->
          %{
            m
            | reply_count: length(rs),
              reply_users: rs |> Enum.map(& &1.user_id) |> Enum.uniq(),
              last_reply_at: List.last(rs).inserted_at
          }
      end
    end)
  end

  # Seeded Sprout replies get the same trace a live reply would have.
  defp attach_bot_traces(messages) do
    Enum.map(messages, fn
      %Message{bot: %{question: q}} = m ->
        plan = Script.plan(q)

        searchable =
          Enum.filter(messages, &(&1.id < m.id and not String.starts_with?(&1.channel_id, "dm-")))

        results = searchable |> Search.rank(plan.query, 3) |> Enum.map(&Search.to_result/1)
        answer = plan.answer || Script.answer_from_results(plan.query, results)

        %{
          m
          | body: answer,
            bot: %{
              status: :done,
              question: q,
              query: plan.query,
              reasoning: plan.reasoning,
              results: results,
              thought_ms: 1800
            }
        }

      m ->
        m
    end)
  end

  defp reactions(list) do
    Enum.map(list, fn
      {emoji, :all} -> %{emoji: emoji, users: @humans}
      {emoji, users} -> %{emoji: emoji, users: users}
    end)
  end

  # Each user has read everything up to a point a few hours back, so every
  # identity lands on a workspace with something new to catch up on.
  defp reads(messages, channels, now) do
    for {handle, i} <- Enum.with_index(@humans),
        channel <- channels,
        handle in channel.members or channel.kind == :channel do
      cutoff = DateTime.add(now, -(150 + i * 45) * 60, :second)

      last =
        messages
        |> Enum.filter(
          &(&1.channel_id == channel.id and DateTime.before?(&1.inserted_at, cutoff))
        )
        |> List.last()

      {{handle, channel.id}, if(last, do: last.id, else: 0)}
    end
  end

  defp image(name, alt) do
    %{
      name: name,
      kind: :image,
      type: "SVG image",
      size: 2400 + String.length(name) * 97,
      url: "/images/seed/#{name}",
      alt: alt
    }
  end

  defp file(name) do
    %{
      name: name,
      kind: :file,
      type: name |> Path.extname() |> String.trim_leading(".") |> String.upcase(),
      size: File.stat!(Path.join(:code.priv_dir(:salad_chat), "static/files/seed/#{name}")).size,
      url: "/files/seed/#{name}",
      alt: name
    }
  end
end
