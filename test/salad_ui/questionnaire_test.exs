defmodule SaladUI.QuestionnaireTest do
  use ComponentCase

  import SaladUI.Questionnaire

  alias SaladUI.Questionnaire.State

  @items [
    %{name: "direction", required: true, choices: ~w(delegation questions both)},
    %{name: "signals", multiple: true, choices: ~w(progress decisions risks)},
    %{name: "timing", required: true, choices: ~w(now later)}
  ]

  # The opening tag of the first element whose tag contains `fragment`.
  defp tag(html, fragment) do
    ~r/<[a-zA-Z][^>]*>/
    |> Regex.scan(html)
    |> List.flatten()
    |> Enum.find(&String.contains?(&1, fragment)) || flunk("no tag with #{fragment}")
  end

  defp render_questionnaire(attrs) do
    assigns = Map.merge(%{items: @items, state: nil, item: nil, default_item: nil, shortcuts: nil}, Map.new(attrs))

    rendered_to_string(~H"""
    <.questionnaire
      :let={q}
      id="plan"
      items={@items}
      state={@state}
      item={@item}
      default_item={@default_item}
      shortcuts={@shortcuts}
    >
      <.questionnaire_progress questionnaire={q} />
      <.questionnaire_item
        :let={item}
        :for={question <- @items}
        questionnaire={q}
        name={question.name}
      >
        <.questionnaire_title>{question.name}?</.questionnaire_title>
        <.questionnaire_description item={item}>About {question.name}</.questionnaire_description>
        <.questionnaire_choices item={item}>
          <.questionnaire_choice :for={value <- question.choices} item={item} value={value}>
            {value}
          </.questionnaire_choice>
          <.questionnaire_input
            :if={question.name == "direction"}
            item={item}
            aria-label="Another answer"
          />
        </.questionnaire_choices>
        <.questionnaire_error item={item} />
      </.questionnaire_item>
      <.questionnaire_actions>
        <.questionnaire_previous />
        <.questionnaire_skip />
        <.questionnaire_next />
        <.questionnaire_submit>Save plan</.questionnaire_submit>
      </.questionnaire_actions>
    </.questionnaire>
    """)
  end

  describe "questionnaire/1" do
    test "renders a novalidate form with the hook, state and hidden fields" do
      html = render_questionnaire(%{})
      form = tag(html, ~s(data-slot="questionnaire"))

      assert form =~ ~r/^<form/
      assert form =~ " novalidate"
      assert form =~ ~s(id="plan")
      assert form =~ ~s(phx-hook="SaladUI")
      assert form =~ ~s(data-component="questionnaire")
      assert form =~ ~s(data-current="1")
      assert form =~ ~s(data-total="3")
      assert form =~ " data-first"
      refute form =~ " data-last"
      assert form =~ " data-required"
      assert form =~ ~s(data-status="unanswered")
      assert form =~ "group/questionnaire flex w-full min-w-0 flex-col gap-4"
      assert form =~ ~s(data-options="{&quot;item&quot;:&quot;direction&quot;)
      assert form =~ "&quot;serverDriven&quot;:false"

      assert tag(html, ~s(data-part="active-input")) =~ ~s(value="direction")
      assert tag(html, ~s(data-part="active-input")) =~ ~s(name="_questionnaire[item]")

      # The first submit button is the form's default button (Enter in a text field).
      default = tag(html, ~s(data-part="default-action"))
      assert default =~ ~s(name="_questionnaire[action]")
      assert default =~ ~s(value="continue")
      assert default =~ ~s(tabindex="-1")
      [first_button | _] = Regex.run(~r/<button[^>]*>/, html)
      assert first_button == default
    end

    test "item or state makes it server-driven" do
      assert render_questionnaire(%{item: "signals"}) =~ "&quot;serverDriven&quot;:true"

      state = State.new(@items)
      html = render_questionnaire(%{state: state})
      assert html =~ "&quot;serverDriven&quot;:true"
      assert tag(html, ~s(data-part="active-input")) =~ ~s(value="direction")
    end

    test "default_item picks the initial item but stays client-driven" do
      html = render_questionnaire(%{default_item: "timing"})

      assert tag(html, ~s(data-part="active-input")) =~ ~s(value="timing")
      assert html =~ "&quot;serverDriven&quot;:false"
      assert tag(html, ~s(data-slot="questionnaire")) =~ " data-last"
    end

    test "with an action it posts a CSRF token like Phoenix forms" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.questionnaire id="post" action="/survey" method="post">
          <.questionnaire_submit />
        </.questionnaire>
        """)

      assert tag(html, "<form") =~ ~s(action="/survey")
      assert html =~ ~s(name="_csrf_token")
    end

    test "shortcuts are exposed on the root and assigned to enabled choices" do
      html = render_questionnaire(%{shortcuts: "letters"})

      assert tag(html, ~s(data-slot="questionnaire")) =~ ~s(data-shortcuts="letters")
      assert tag(html, ~s(data-part="choices")) =~ ~s(data-shortcuts="letters")
      assert tag(html, ~s(<label data-slot="questionnaire-choice")) =~ ~s(data-shortcut="A")
      assert tag(html, ~s(value="questions")) =~ ~s(aria-keyshortcuts="B")
      assert html =~ ~r/data-slot="questionnaire-choice-shortcut"[^>]*>\s*C\s*</

      numbers = render_questionnaire(%{shortcuts: "numbers"})
      assert tag(numbers, ~s(value="both")) =~ ~s(aria-keyshortcuts="3")
    end
  end

  describe "server-rendered steps" do
    test "only the active item is visible; the rest are hidden and inert" do
      html = render_questionnaire(%{item: "signals"})

      active = tag(html, ~s(data-name="signals"))
      assert active =~ ~r/^<fieldset/
      assert active =~ " data-active"
      assert active =~ " data-multiple"
      refute active =~ " hidden"
      assert active =~ ~s(tabindex="-1")

      inactive = tag(html, ~s(data-name="direction"))
      assert inactive =~ " hidden"
      assert inactive =~ " inert"
      assert inactive =~ " data-required"
      refute inactive =~ " data-active"
    end

    test "progress is a named progressbar" do
      html = render_questionnaire(%{item: "signals"})
      progress = tag(html, ~s(data-slot="questionnaire-progress"))

      assert progress =~ ~s(role="progressbar")
      assert progress =~ ~s(aria-label="Questionnaire progress")
      assert progress =~ ~s(aria-valuemin="1")
      assert progress =~ ~s(aria-valuemax="3")
      assert progress =~ ~s(aria-valuenow="2")
      assert progress =~ ~s(aria-valuetext="Question 2 of 3")
      assert progress =~ " data-default-label"
      assert html =~ ~r/data-slot="questionnaire-progress"[^>]*>\s*Question 2 of 3\s*</
    end

    test "single choices are radios and multiple choices checkboxes, named name[]" do
      html = render_questionnaire(%{})

      radio = tag(html, ~s(value="delegation"))
      assert radio =~ ~s(type="radio")
      assert radio =~ ~s(name="direction[]")
      assert radio =~ ~s(data-slot="questionnaire-choice-input")

      checkbox = tag(html, ~s(value="risks"))
      assert checkbox =~ ~s(type="checkbox")
      assert checkbox =~ ~s(name="signals[]")

      assert html =~ ~s(data-slot="questionnaire-choice-indicator-dot")
      assert html =~ ~s(data-slot="questionnaire-choice-indicator-check")
      assert tag(html, ~s(data-type="checkbox")) =~ ~s(data-slot="questionnaire-choice")
    end

    test "answers check choices and fill the freeform input" do
      state =
        State.new(@items, answers: %{"direction" => "Something else", "signals" => ["progress", "risks"]})

      html = render_questionnaire(%{state: state})

      assert tag(html, ~s(value="progress")) =~ " checked"
      assert tag(html, ~s(value="risks")) =~ " checked"
      refute tag(html, ~s(value="decisions")) =~ " checked"
      refute tag(html, ~s(value="delegation")) =~ " checked"

      input = tag(html, ~s(data-slot="questionnaire-input"))
      assert input =~ ~s(value="Something else")
      assert input =~ ~s(name="direction[]")
      assert input =~ " data-filled"
      assert input =~ ~s(aria-label="Another answer")

      assert tag(html, ~s(data-name="direction")) =~ ~s(data-status="answered")

      assert tag(html, ~s(<label data-slot="questionnaire-choice" data-part="choice" data-type="checkbox")) =~
               " data-checked"
    end

    test "a fixed answer does not leak into the freeform input" do
      state = State.new(@items, answers: %{"direction" => "questions"})
      html = render_questionnaire(%{state: state})

      assert tag(html, ~s(value="questions")) =~ " checked"
      refute tag(html, ~s(data-slot="questionnaire-input")) =~ "value="
    end

    test "errors mark the item invalid and show the message" do
      state = %{State.new(@items) | errors: %{"direction" => true}}
      html = render_questionnaire(%{state: state})

      item = tag(html, ~s(data-name="direction"))
      assert item =~ " data-invalid"
      assert item =~ ~s(aria-invalid="true")
      assert tag(html, ~s(value="delegation")) =~ ~s(aria-invalid="true")

      error = tag(html, ~s(id="plan-direction-error"))
      assert error =~ ~s(role="alert")
      refute error =~ " hidden"
      assert html =~ "Choose an answer to continue."

      # Optional items get the skip hint; hidden while valid.
      optional = tag(html, ~s(id="plan-signals-error"))
      assert optional =~ " hidden"
      assert html =~ "Choose an answer or skip this question."

      custom = %{State.new(@items) | errors: %{"direction" => "Pick a direction."}}
      assert render_questionnaire(%{state: custom}) =~ "Pick a direction."
    end

    test "skipped items render a hidden field and the skipped status" do
      state = %{State.new(@items) | skipped: ["signals"], item: "timing"}
      html = render_questionnaire(%{state: state})

      assert tag(html, ~s(data-part="skipped-input")) =~ ~s(name="_questionnaire[skipped][]")
      assert tag(html, ~s(data-part="skipped-input")) =~ ~s(value="signals")
      assert tag(html, ~s(data-name="signals")) =~ ~s(data-status="skipped")
      assert tag(html, ~s(data-slot="questionnaire")) =~ " data-last"
    end

    test "disabled items are disabled fieldsets left out of progress" do
      items = [
        %{name: "runtime", required: true, choices: ~w(local remote)},
        %{name: "region", required: true, disabled: true, choices: ~w(us eu)},
        %{name: "approval", required: true, choices: ~w(ask)}
      ]

      html = render_questionnaire(%{items: items, item: "approval"})

      region = tag(html, ~s(data-name="region"))
      assert region =~ " disabled"
      assert region =~ " data-disabled"
      assert region =~ " hidden"
      assert tag(html, ~s(value="us")) =~ " disabled"
      assert tag(html, ~s(data-slot="questionnaire")) =~ ~s(data-total="2")
      assert html =~ "Question 2 of 2"
    end

    test "description and error get ids from the item" do
      html = render_questionnaire(%{})

      assert tag(html, ~s(data-slot="questionnaire-description")) =~ ~s(id="plan-direction-description")
      assert tag(html, ~s(data-name="direction")) =~ ~s(id="plan-direction")
    end
  end

  describe "parts" do
    test "title renders the fieldset legend, or another element with as" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.questionnaire_title>Question</.questionnaire_title>
        <.questionnaire_title as="div" id="t" class="text-lg">Card</.questionnaire_title>
        """)

      assert tag(html, ~s(data-slot="questionnaire-title")) =~ ~r/^<legend/
      assert html =~ "[&amp;:not(:has(~[data-slot=questionnaire-description]))]:mb-4"
      div = tag(html, ~s(id="t"))
      assert div =~ ~r/^<div/
      assert div =~ "text-lg"
    end

    test "actions are submit buttons posting their action" do
      html = render_questionnaire(%{})

      for {action, variant} <- [previous: "outline", skip: "outline", next: "default", submit: "default"] do
        button = tag(html, ~s(data-slot="questionnaire-#{action}"))
        assert button =~ ~s(type="submit")
        assert button =~ ~s(name="_questionnaire[action]")
        assert button =~ ~s(value="#{action}")
        assert button =~ ~s(data-variant="#{variant}")
      end

      assert tag(html, ~s(data-slot="questionnaire-previous")) =~ "group-data-first/questionnaire:hidden"
      assert tag(html, ~s(data-slot="questionnaire-skip")) =~ "group-data-required/questionnaire:hidden"
      assert tag(html, ~s(data-slot="questionnaire-next")) =~ "group-data-last/questionnaire:hidden"
      assert tag(html, ~s(data-slot="questionnaire-submit")) =~ "not-group-data-last/questionnaire:hidden"
      assert html =~ ~r/>\s*Previous\s*</
      assert html =~ ~r/>\s*Save plan\s*</
      assert tag(html, ~s(data-slot="questionnaire-actions")) =~ "grid-cols-[minmax(0,1fr)_auto_auto]"
    end

    test "actions accept variant, size and disabled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.questionnaire_next
          variant="secondary"
          size="sm"
          disabled
          class="data-[status=unanswered]:opacity-50"
        >
          Continue
        </.questionnaire_next>
        """)

      button = tag(html, "<button")
      assert button =~ ~s(data-variant="secondary")
      assert button =~ ~s(data-size="sm")
      assert button =~ " disabled"
      assert button =~ "bg-secondary"
      assert button =~ "data-[status=unanswered]:opacity-50"
    end

    test "custom progress content receives the progress state" do
      assigns = %{items: @items}

      html =
        rendered_to_string(~H"""
        <.questionnaire :let={q} id="custom" items={@items} item="signals">
          <.questionnaire_progress :let={p} questionnaire={q} aria-label="Setup progress">
            <span :for={step <- 1..p.total} data-progress-step={step} data-complete={step <= p.current} />
            Checkpoint <span data-progress-current>{p.current}</span>
            of <span data-progress-total>{p.total}</span>
          </.questionnaire_progress>
        </.questionnaire>
        """)

      progress = tag(html, ~s(data-slot="questionnaire-progress"))
      assert progress =~ ~s(aria-label="Setup progress")
      refute progress =~ "data-default-label"
      assert html =~ ~r/data-progress-current[^>]*>2</
      assert html =~ ~r/data-progress-total[^>]*>3</
      assert html =~ ~s(data-progress-step="2" data-complete)
    end

    test "choice description and the checked look work without JavaScript" do
      assigns = %{
        item: %{
          name: "x",
          input_name: "x[]",
          id: nil,
          multiple: false,
          disabled: false,
          invalid: false,
          status: "unanswered",
          values: [],
          shortcuts: %{}
        }
      }

      html =
        rendered_to_string(~H"""
        <.questionnaire_choice item={@item} value="a" checked>
          <span>A</span>
          <.questionnaire_choice_description>More</.questionnaire_choice_description>
        </.questionnaire_choice>
        """)

      assert tag(html, ~s(data-slot="questionnaire-choice-description")) =~ "text-muted-foreground"
      assert tag(html, ~s(<input type="radio")) =~ " checked"
      assert tag(html, "<label") =~ " data-checked"
      assert tag(html, "<label") =~ "has-[&gt;input:checked]:bg-muted"

      assert html =~ "group-has-[>input:checked]/questionnaire-choice:block"
    end

    test "every part carries one data-slot" do
      html = render_questionnaire(%{shortcuts: "letters"})

      for slot <-
            ~w(questionnaire questionnaire-progress questionnaire-item questionnaire-title questionnaire-description
               questionnaire-choices questionnaire-choice questionnaire-choice-input questionnaire-choice-indicator
               questionnaire-choice-label questionnaire-choice-shortcut questionnaire-input-wrapper questionnaire-input
               questionnaire-error questionnaire-actions questionnaire-previous questionnaire-skip questionnaire-next
               questionnaire-submit) do
        assert html =~ ~s(data-slot="#{slot}"), "missing #{slot}"
      end

      for [open] <- Regex.scan(~r/<[a-zA-Z][^>]*>/, html) do
        assert length(Regex.scan(~r/\sdata-slot=/, open)) <= 1, "duplicate data-slot in #{open}"
      end
    end
  end

  describe "State" do
    defp params(meta, answers \\ %{}), do: Map.put(answers, "_questionnaire", meta)

    test "new/2 starts on the first enabled item" do
      items = [%{name: "a", disabled: true}, %{name: "b"}]
      assert %State{item: "b", answers: %{}, skipped: [], errors: %{}} = State.new(items)
      assert State.new(@items, item: "timing").item == "timing"
      assert State.new(@items, item: "missing").item == "direction"
    end

    test "answers/2 reads single, multiple and freeform answers" do
      params = %{
        "direction" => ["questions", "  "],
        "signals" => ["progress", "risks", ""],
        "timing" => [""]
      }

      assert State.answers(@items, params) == %{"direction" => "questions", "signals" => ["progress", "risks"]}

      # Without JavaScript a typed answer is posted after the checked radio: it wins.
      assert State.answers(@items, %{"direction" => ["questions", "My own"]}) == %{"direction" => "My own"}
    end

    test "next validates the active item" do
      state = State.update(@items, params(%{"item" => "direction", "action" => "next"}))
      assert state.item == "direction"
      assert state.errors == %{"direction" => true}
      refute state.submitted

      state = State.update(@items, params(%{"item" => "direction", "action" => "next"}, %{"direction" => ["both"]}))
      assert state.item == "signals"
      assert state.errors == %{}
      assert state.answers == %{"direction" => "both"}
      assert State.status(state, "direction") == "answered"
    end

    test "previous moves back without validating" do
      state = State.update(@items, params(%{"item" => "signals", "action" => "previous"}))
      assert state.item == "direction"
      assert state.errors == %{}

      assert State.update(@items, params(%{"item" => "direction", "action" => "previous"})).item == "direction"
    end

    test "skip records an optional item, drops its answer and moves on" do
      state =
        State.update(@items, params(%{"item" => "signals", "action" => "skip"}, %{"signals" => ["risks"]}))

      assert state.item == "timing"
      assert state.skipped == ["signals"]
      refute Map.has_key?(state.answers, "signals")
      assert State.status(state, "signals") == "skipped"

      required = State.update(@items, params(%{"item" => "direction", "action" => "skip"}))
      assert required.item == "direction"
      assert required.errors == %{"direction" => true}
    end

    test "skipped items stay skipped until answered" do
      meta = %{"item" => "timing", "skipped" => ["signals"]}
      assert State.update(@items, params(meta)).skipped == ["signals"]
      assert State.update(@items, params(meta, %{"signals" => ["risks"]})).skipped == []
      # Required items cannot be skipped.
      assert State.update(@items, params(%{"skipped" => ["direction"]})).skipped == []
    end

    test "submit validates every item and opens the first invalid one" do
      answers = %{"direction" => ["both"], "timing" => ["now"]}

      state = State.update(@items, params(%{"item" => "timing", "action" => "submit"}, answers))
      assert state.item == "signals"
      assert state.errors == %{"signals" => true}
      refute state.submitted

      meta = %{"item" => "timing", "action" => "submit", "skipped" => ["signals"]}
      state = State.update(@items, params(meta, answers))
      assert state.submitted
      assert state.answers == %{"direction" => "both", "timing" => "now"}
    end

    test "continue is next, or submit on the last item" do
      answers = %{"direction" => ["both"], "signals" => ["risks"], "timing" => ["now"]}

      assert State.update(@items, params(%{"item" => "direction", "action" => "continue"}, answers)).item == "signals"
      assert State.update(@items, params(%{"item" => "timing", "action" => "continue"}, answers)).submitted
    end

    test "skip on the last item submits" do
      items = [%{name: "scope", required: true}, %{name: "notes"}]
      state = State.update(items, params(%{"item" => "notes", "action" => "skip"}, %{"scope" => ["x"]}))

      assert state.submitted
      assert state.skipped == ["notes"]
    end

    test "no action keeps the step (phx-change)" do
      state = State.update(@items, params(%{"item" => "signals"}, %{"signals" => ["risks"]}))
      assert state.item == "signals"
      assert state.action == nil
      assert state.errors == %{}
      assert state.answers == %{"signals" => ["risks"]}
    end

    test "disabled items are ignored for navigation, validation and answers" do
      items = [
        %{name: "runtime", required: true},
        %{name: "region", required: true, disabled: true},
        %{name: "approval", required: true}
      ]

      answers = %{"runtime" => ["local"], "region" => ["us"], "approval" => ["ask"]}
      next = State.update(items, params(%{"item" => "runtime", "action" => "next"}, answers))
      assert next.item == "approval"

      done = State.update(items, params(%{"item" => "approval", "action" => "submit"}, answers))
      assert done.submitted
      assert done.answers == %{"runtime" => "local", "approval" => "ask"}
    end

    test "items may be keyword lists or string-keyed maps" do
      items = [[name: :a, required: true], %{"name" => "b", "multiple" => true}]
      state = State.update(items, params(%{"item" => "a", "action" => "next"}, %{"a" => ["1"], "b" => ["x", "y"]}))

      assert state.item == "b"
      assert state.answers == %{"a" => "1", "b" => ["x", "y"]}
    end
  end
end
