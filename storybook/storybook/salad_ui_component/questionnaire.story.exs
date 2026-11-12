defmodule Storybook.SaladUIComponents.Questionnaire do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Button
  alias SaladUI.Card
  alias SaladUI.Dialog
  alias SaladUI.Questionnaire

  def function, do: &Questionnaire.questionnaire/1

  def imports,
    do: [
      {Questionnaire,
       [
         questionnaire_progress: 1,
         questionnaire_item: 1,
         questionnaire_title: 1,
         questionnaire_description: 1,
         questionnaire_choices: 1,
         questionnaire_choice: 1,
         questionnaire_choice_description: 1,
         questionnaire_input: 1,
         questionnaire_error: 1,
         questionnaire_actions: 1,
         questionnaire_previous: 1,
         questionnaire_skip: 1,
         questionnaire_next: 1,
         questionnaire_submit: 1
       ]},
      {Button, [button: 1]},
      {Card, [card: 1, card_header: 1, card_title: 1, card_description: 1, card_action: 1, card_content: 1, card_footer: 1]},
      {Dialog,
       [
         dialog: 1,
         dialog_trigger: 1,
         dialog_content: 1,
         dialog_header: 1,
         dialog_title: 1,
         dialog_description: 1,
         dialog_footer: 1
       ]}
    ]

  @doc false
  def items(:demo) do
    [
      %{
        name: "direction",
        required: true,
        prompt: "What should the agent build next?",
        description: "Choose a direction or describe another task.",
        choices: [
          %{value: "tool-calls", label: "Tool call timeline", description: "Show what the agent ran and what came back."},
          %{value: "approvals", label: "Approval checkpoints", description: "Ask before sensitive or destructive actions."},
          %{value: "handoffs", label: "Sub-agent handoffs", description: "Make delegated work and results easier to follow."}
        ],
        input: %{label: "Another agent feature", placeholder: "Describe another feature…"}
      },
      %{
        name: "signals",
        multiple: true,
        prompt: "What should every progress update include?",
        description: "Select all that apply, or skip this question.",
        choices: [
          %{value: "progress", label: "Progress"},
          %{value: "decisions", label: "Decisions"},
          %{value: "risks", label: "Risks"},
          %{value: "next-step", label: "Next step"}
        ]
      },
      %{
        name: "timing",
        required: true,
        prompt: "When should work begin?",
        description: "Choose when the agent should begin the work.",
        choices: [
          %{value: "now", label: "Start now"},
          %{value: "next-cycle", label: "Next development cycle"},
          %{value: "backlog", label: "Add it to the backlog"}
        ]
      }
    ]
  end

  def items(:progress) do
    [
      %{
        name: "scope",
        required: true,
        prompt: "How large is the change?",
        choices: [
          %{value: "small", label: "Small patch"},
          %{value: "medium", label: "Feature-sized change"},
          %{value: "large", label: "Cross-package change"}
        ]
      },
      %{
        name: "strategy",
        required: true,
        prompt: "How should commits be organized?",
        choices: [
          %{value: "single", label: "Single commit"},
          %{value: "logical", label: "Logical commits"},
          %{value: "squash", label: "Squash before review"}
        ]
      },
      %{
        name: "tests",
        required: true,
        prompt: "Which tests should run?",
        choices: [
          %{value: "targeted", label: "Targeted tests"},
          %{value: "package", label: "Package suite"},
          %{value: "workspace", label: "Full workspace"}
        ]
      },
      %{
        name: "delivery",
        required: true,
        prompt: "How should the work be delivered?",
        choices: [
          %{value: "patch", label: "Patch only"},
          %{value: "commit", label: "Committed locally"},
          %{value: "branch", label: "Push a review branch"}
        ]
      }
    ]
  end

  def items(:task) do
    [
      %{
        name: "task",
        required: true,
        prompt: "What should the agent work on?",
        description: "Choose the task that should be handled next.",
        choices: [
          %{value: "bug", label: "Fix the failing test"},
          %{value: "feature", label: "Build the settings page"},
          %{value: "docs", label: "Update the docs"}
        ]
      },
      %{
        name: "review",
        prompt: "Who should review it?",
        description: "Skip this if anyone can review.",
        choices: [%{value: "me", label: "Me"}, %{value: "team", label: "The team"}]
      }
    ]
  end

  # A JS command for the final (valid) submit: show a confirmation instead of
  # posting the page, since component stories have no server handler.
  @doc false
  def saved(id), do: Phoenix.LiveView.JS.show(to: "##{id}-saved")

  def variations do
    [
      %Variation{
        id: :demo,
        description:
          "shadcn's demo: three items (required single choice with a freeform answer, optional multiple choice, required single choice), letter shortcuts, progress and Previous / Skip / Next / Submit. Try A/B/C, the arrow keys and Enter.",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire
            :let={q}
            id="qs-demo"
            items={Storybook.SaladUIComponents.Questionnaire.items(:demo)}
            default_item="direction"
            shortcuts="letters"
            phx-submit={Storybook.SaladUIComponents.Questionnaire.saved("qs-demo")}
          >
            <.questionnaire_progress questionnaire={q} />
            <.questionnaire_item
              :for={question <- Storybook.SaladUIComponents.Questionnaire.items(:demo)}
              :let={item}
              questionnaire={q}
              name={question.name}
            >
              <.questionnaire_title>{question.prompt}</.questionnaire_title>
              <.questionnaire_description item={item}>{question.description}</.questionnaire_description>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
                  <span class="font-medium">{choice.label}</span>
                  <.questionnaire_choice_description :if={choice[:description]}>
                    {choice.description}
                  </.questionnaire_choice_description>
                </.questionnaire_choice>
                <.questionnaire_input
                  :if={question[:input]}
                  item={item}
                  aria-label={question.input.label}
                  placeholder={question.input.placeholder}
                />
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_previous />
              <.questionnaire_skip />
              <.questionnaire_next>Next</.questionnaire_next>
              <.questionnaire_submit>Save plan</.questionnaire_submit>
            </.questionnaire_actions>
          </.questionnaire>
          <p id="qs-demo-saved" class="hidden pt-4 text-sm text-muted-foreground">Agent plan saved.</p>
        </div>
        """
      },
      %Variation{
        id: :multiple,
        description: "`multiple` renders checkboxes; the answer is a list.",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire :let={q} id="qs-multiple" items={[%{name: "signals", required: true, multiple: true}]}>
            <.questionnaire_item :let={item} questionnaire={q} name="signals">
              <.questionnaire_title>What should every update include?</.questionnaire_title>
              <.questionnaire_description item={item}>Select all that apply.</.questionnaire_description>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice item={item} value="progress">Progress</.questionnaire_choice>
                <.questionnaire_choice item={item} value="decisions">Decisions</.questionnaire_choice>
                <.questionnaire_choice item={item} value="risks">Risks</.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_submit />
            </.questionnaire_actions>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :freeform,
        description: "`questionnaire_input` next to fixed choices: typing replaces the selected choice and vice versa.",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire :let={q} id="qs-freeform" items={[%{name: "prototype", required: true, choices: ~w(delegation questions)}]}>
            <.questionnaire_item :let={item} questionnaire={q} name="prototype">
              <.questionnaire_title>What should we prototype next?</.questionnaire_title>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice item={item} value="delegation">Delegation</.questionnaire_choice>
                <.questionnaire_choice item={item} value="questions">Question prompts</.questionnaire_choice>
                <.questionnaire_input
                  item={item}
                  aria-label="Another prototype direction"
                  placeholder="Type another direction…"
                />
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_submit />
            </.questionnaire_actions>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :skip,
        description:
          "`questionnaire_skip` records an optional item as intentionally unanswered (it posts no answer and is listed in `_questionnaire[skipped][]`).",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire
            :let={q}
            id="qs-skip"
            items={[%{name: "scope", required: true}, %{name: "timing"}]}
            phx-submit={Storybook.SaladUIComponents.Questionnaire.saved("qs-skip")}
          >
            <.questionnaire_progress questionnaire={q} />
            <.questionnaire_item :let={item} questionnaire={q} name="scope">
              <.questionnaire_title>Which files are in scope?</.questionnaire_title>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice item={item} value="component">Component only</.questionnaire_choice>
                <.questionnaire_choice item={item} value="package">Whole package</.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_item :let={item} questionnaire={q} name="timing">
              <.questionnaire_title>When should this be revisited?</.questionnaire_title>
              <.questionnaire_description item={item}>Skip this if timing has not been decided.</.questionnaire_description>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice item={item} value="week">This week</.questionnaire_choice>
                <.questionnaire_choice item={item} value="cycle">Next cycle</.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_previous />
              <.questionnaire_skip />
              <.questionnaire_next />
              <.questionnaire_submit />
            </.questionnaire_actions>
          </.questionnaire>
          <p id="qs-skip-saved" class="hidden pt-4 text-sm text-muted-foreground">Submitted.</p>
        </div>
        """
      },
      %Variation{
        id: :shortcuts,
        description:
          ~s|`shortcuts="letters"` assigns A–Z (`"numbers"`: 1–9) to each enabled choice. Selecting by shortcut does not advance.|,
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire
            :let={q}
            id="qs-shortcuts"
            shortcuts="letters"
            items={[%{name: "review", required: true, choices: ~w(api tests docs)}]}
          >
            <.questionnaire_item :let={item} questionnaire={q} name="review">
              <.questionnaire_title>What should the agent review?</.questionnaire_title>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice item={item} value="api">Public API</.questionnaire_choice>
                <.questionnaire_choice item={item} value="tests">Test coverage</.questionnaire_choice>
                <.questionnaire_choice item={item} value="docs">Documentation</.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_submit />
            </.questionnaire_actions>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :resume,
        description:
          "Restore a saved draft: `default_item` opens the second item, `checked` and `value` are the saved answers, and a native reset goes back to them.",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire
            :let={q}
            id="qs-resume"
            default_item="verification"
            items={[%{name: "scope", required: true}, %{name: "verification", required: true}]}
          >
            <.questionnaire_progress questionnaire={q} />
            <.questionnaire_item :let={item} questionnaire={q} name="scope">
              <.questionnaire_title>Which files are in scope?</.questionnaire_title>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice item={item} value="component" checked>Component only</.questionnaire_choice>
                <.questionnaire_choice item={item} value="package">Whole package</.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_item :let={item} questionnaire={q} name="verification">
              <.questionnaire_title>Any extra instructions?</.questionnaire_title>
              <.questionnaire_input item={item} aria-label="Extra instructions" value="Run the package tests." />
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.button type="reset" variant="ghost" class="col-start-2 row-start-1">Reset draft</.button>
              <.questionnaire_previous />
              <.questionnaire_next />
              <.questionnaire_submit />
            </.questionnaire_actions>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :custom_progress,
        description:
          "Custom progress with `:let={p}`. In the browser the hook updates `data-progress-current`/`data-progress-total` text and `data-complete` on `data-progress-step` elements.",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire :let={q} id="qs-progress" items={Storybook.SaladUIComponents.Questionnaire.items(:progress)}>
            <.questionnaire_progress :let={p} questionnaire={q} aria-label="Setup progress" class="w-full">
              <div class="mb-2 flex gap-1.5" aria-hidden="true">
                <span
                  :for={step <- 1..p.total}
                  data-progress-step={step}
                  data-complete={step <= p.current}
                  class="h-1.5 flex-1 rounded-full bg-muted data-complete:bg-primary"
                />
              </div>
              <span>
                Checkpoint <span data-progress-current>{p.current}</span> of <span data-progress-total>{p.total}</span>
              </span>
            </.questionnaire_progress>
            <.questionnaire_item
              :for={question <- Storybook.SaladUIComponents.Questionnaire.items(:progress)}
              :let={item}
              questionnaire={q}
              name={question.name}
            >
              <.questionnaire_title>{question.prompt}</.questionnaire_title>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
                  {choice.label}
                </.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_previous />
              <.questionnaire_next />
              <.questionnaire_submit>Finish plan</.questionnaire_submit>
            </.questionnaire_actions>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :animated,
        description:
          "Animate the entering item with `data-active:` classes; progress and actions stay put. Inactive items hide immediately.",
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire :let={q} id="qs-animated" items={Storybook.SaladUIComponents.Questionnaire.items(:progress)}>
            <.questionnaire_progress questionnaire={q} />
            <.questionnaire_item
              :for={question <- Storybook.SaladUIComponents.Questionnaire.items(:progress)}
              :let={item}
              questionnaire={q}
              name={question.name}
              class="data-active:animate-in data-active:duration-300 data-active:fade-in-0 data-active:slide-in-from-bottom-2 motion-reduce:animate-none"
            >
              <.questionnaire_title>{question.prompt}</.questionnaire_title>
              <.questionnaire_choices item={item}>
                <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
                  {choice.label}
                </.questionnaire_choice>
              </.questionnaire_choices>
              <.questionnaire_error item={item} />
            </.questionnaire_item>
            <.questionnaire_actions>
              <.questionnaire_previous />
              <.questionnaire_next />
              <.questionnaire_submit />
            </.questionnaire_actions>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :card,
        description:
          ~s|Card composition: the title and description live in the card header (`as="div"` plus the item's `aria-labelledby`), progress in `card_action`, actions in the footer.|,
        template: """
        <div class="mx-auto w-full max-w-md">
          <.questionnaire :let={q} id="qs-card" items={Storybook.SaladUIComponents.Questionnaire.items(:task)}>
            <.card>
              <.questionnaire_item
                :for={question <- Storybook.SaladUIComponents.Questionnaire.items(:task)}
                :let={item}
                questionnaire={q}
                name={question.name}
                aria-labelledby={"qs-card-" <> question.name <> "-title"}
                class="gap-6"
              >
                <.card_header>
                  <.questionnaire_title as="div" id={"qs-card-" <> question.name <> "-title"} class="mb-0 leading-none font-semibold">
                    {question.prompt}
                  </.questionnaire_title>
                  <.questionnaire_description item={item}>{question.description}</.questionnaire_description>
                  <.card_action>
                    <.questionnaire_progress questionnaire={q} />
                  </.card_action>
                </.card_header>
                <.card_content>
                  <.questionnaire_choices item={item}>
                    <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
                      {choice.label}
                    </.questionnaire_choice>
                  </.questionnaire_choices>
                  <.questionnaire_error item={item} />
                </.card_content>
              </.questionnaire_item>
              <.card_footer>
                <.questionnaire_actions>
                  <.questionnaire_previous />
                  <.questionnaire_skip />
                  <.questionnaire_next />
                  <.questionnaire_submit />
                </.questionnaire_actions>
              </.card_footer>
            </.card>
          </.questionnaire>
        </div>
        """
      },
      %Variation{
        id: :dialog,
        description:
          "Inside a dialog. Cancel closes the dialog (the host owns dismissal); Skip records an intentional unanswered item.",
        template: """
        <.dialog id="qs-dialog">
          <.dialog_trigger>
            <.button variant="outline">Open clarification</.button>
          </.dialog_trigger>
          <.dialog_content class="sm:max-w-md">
            <.questionnaire
              :let={q}
              id="qs-dialog-form"
              items={Storybook.SaladUIComponents.Questionnaire.items(:task)}
              phx-submit={SaladUI.JS.dispatch_command("close", to: "#qs-dialog")}
            >
              <.questionnaire_item
                :for={question <- Storybook.SaladUIComponents.Questionnaire.items(:task)}
                :let={item}
                questionnaire={q}
                name={question.name}
                aria-labelledby={"qs-dialog-" <> question.name <> "-title"}
              >
                <.dialog_header>
                  <.questionnaire_progress questionnaire={q} />
                  <.questionnaire_title as="h2" id={"qs-dialog-" <> question.name <> "-title"} class="mb-0 text-lg leading-none font-semibold">
                    {question.prompt}
                  </.questionnaire_title>
                  <.questionnaire_description item={item}>{question.description}</.questionnaire_description>
                </.dialog_header>
                <.questionnaire_choices item={item}>
                  <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
                    {choice.label}
                  </.questionnaire_choice>
                </.questionnaire_choices>
                <.questionnaire_error item={item} />
              </.questionnaire_item>
              <.dialog_footer>
                <.button type="button" variant="outline" phx-click={SaladUI.JS.dispatch_command("close", to: "#qs-dialog")}>
                  Cancel
                </.button>
                <.questionnaire_skip />
                <.questionnaire_next />
                <.questionnaire_submit>Send answer</.questionnaire_submit>
              </.dialog_footer>
            </.questionnaire>
          </.dialog_content>
        </.dialog>
        """
      }
    ]
  end
end
