defmodule Storybook.Examples.Questionnaire do
  @moduledoc false
  use PhoenixStorybook.Story, :example

  import SaladUI.Questionnaire

  alias SaladUI.Questionnaire.State

  def doc do
    "Server-driven questionnaires: the LiveView owns the active item. Every action posts the form and `SaladUI.Questionnaire.State.update/2` computes the next step, so the same handler works with JavaScript disabled (a plain POST). Covers shadcn's controlled, navigation-state, conditional-items and custom-validation examples."
  end

  @permission [
    %{
      name: "permission",
      required: true,
      prompt: "What may the agent modify?",
      description: "Next is disabled until an answer is selected.",
      choices: [
        %{value: "files", label: "Project files"},
        %{value: "tests", label: "Project files and tests"},
        %{value: "config", label: "Files, tests, and configuration"}
      ]
    },
    %{
      name: "verification",
      required: true,
      prompt: "What must pass before completion?",
      choices: [
        %{value: "tests", label: "Tests"},
        %{value: "types", label: "Tests and types"},
        %{value: "all", label: "Tests, types, and visual QA"}
      ]
    }
  ]

  @validation [
    %{
      name: "detail",
      required: true,
      prompt: "How much detail should the answer include?",
      choices: [%{value: "summary", label: "A short summary"}, %{value: "complete", label: "A complete answer"}]
    },
    %{
      name: "audience",
      required: true,
      prompt: "Who will read it?",
      choices: [%{value: "team", label: "The team"}, %{value: "public", label: "The public"}]
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       permission: State.new(@permission),
       permission_result: nil,
       conditional: State.new(conditional_items("local")),
       runtime: "local",
       conditional_result: nil,
       validation: State.new(@validation),
       validation_result: nil
     )}
  end

  defp conditional_items(runtime) do
    [
      %{
        name: "runtime",
        required: true,
        prompt: "Where should the agent run?",
        choices: [%{value: "local", label: "Locally"}, %{value: "remote", label: "Remote environment"}]
      },
      %{
        name: "region",
        required: true,
        disabled: runtime != "remote",
        prompt: "Which region should the remote environment use?",
        choices: [%{value: "us", label: "United States"}, %{value: "eu", label: "Europe"}]
      },
      %{
        name: "approval",
        required: true,
        prompt: "When should the agent ask for approval?",
        choices: [%{value: "always", label: "Before every change"}, %{value: "risky", label: "Only for risky changes"}]
      }
    ]
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        permission_items: @permission,
        validation_items: @validation,
        conditional_items: conditional_items(assigns.runtime)
      )

    ~H"""
    <div class="mx-auto grid max-w-md gap-12 py-8">
      <section class="grid gap-4">
        <h3 class="text-sm font-semibold">Controlled with navigation state</h3>
        <.questionnaire
          :let={q}
          id="permission-questionnaire"
          items={@permission_items}
          state={@permission}
          phx-change="permission"
          phx-submit="permission"
        >
          <.questionnaire_progress questionnaire={q} />
          <.questionnaire_item :for={question <- @permission_items} :let={item} questionnaire={q} name={question.name}>
            <.questionnaire_title>{question.prompt}</.questionnaire_title>
            <.questionnaire_description :if={question[:description]} item={item}>
              {question.description}
            </.questionnaire_description>
            <.questionnaire_choices item={item}>
              <.questionnaire_choice :for={choice <- question.choices} item={item} value={choice.value}>
                {choice.label}
              </.questionnaire_choice>
            </.questionnaire_choices>
            <.questionnaire_error item={item} />
          </.questionnaire_item>
          <.questionnaire_actions>
            <.questionnaire_previous />
            <.questionnaire_next
              variant="secondary"
              disabled={State.status(@permission, @permission.item) == "unanswered"}
              class="data-[status=unanswered]:opacity-50"
            >
              Next
            </.questionnaire_next>
            <.questionnaire_submit disabled={State.status(@permission, @permission.item) == "unanswered"}>
              Save permissions
            </.questionnaire_submit>
          </.questionnaire_actions>
        </.questionnaire>
        <p :if={@permission_result} class="text-sm text-muted-foreground">{@permission_result}</p>
      </section>

      <section class="grid gap-4">
        <h3 class="text-sm font-semibold">Conditional items</h3>
        <.questionnaire
          :let={q}
          id="conditional-questionnaire"
          items={@conditional_items}
          state={@conditional}
          phx-change="conditional"
          phx-submit="conditional"
        >
          <.questionnaire_progress questionnaire={q} />
          <.questionnaire_item :for={question <- @conditional_items} :let={item} questionnaire={q} name={question.name}>
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
        <p :if={@conditional_result} class="text-sm text-muted-foreground">{@conditional_result}</p>
      </section>

      <section class="grid gap-4">
        <h3 class="text-sm font-semibold">Custom validation</h3>
        <.questionnaire
          :let={q}
          id="validation-questionnaire"
          items={@validation_items}
          state={@validation}
          phx-submit="validation"
        >
          <.questionnaire_progress :let={p} questionnaire={q} class="min-w-0">
            {p.current} / {p.total}
          </.questionnaire_progress>
          <.questionnaire_item :for={question <- @validation_items} :let={item} questionnaire={q} name={question.name}>
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
        <p :if={@validation_result} class="text-sm text-muted-foreground">{@validation_result}</p>
      </section>
    </div>
    """
  end

  @impl true
  def handle_event("permission", params, socket) do
    state = State.update(@permission, params)

    if state.submitted do
      {:noreply,
       assign(socket,
         permission: State.new(@permission),
         permission_result: "Saved: #{inspect(state.answers)}"
       )}
    else
      {:noreply, assign(socket, permission: state)}
    end
  end

  def handle_event("conditional", params, socket) do
    # The runtime answer decides whether "region" applies, so read it first.
    runtime = State.answers(conditional_items("remote"), params)["runtime"] || socket.assigns.runtime
    state = State.update(conditional_items(runtime), params)

    if state.submitted do
      {:noreply,
       assign(socket,
         runtime: "local",
         conditional: State.new(conditional_items("local")),
         conditional_result: "Saved: #{inspect(state.answers)}"
       )}
    else
      {:noreply, assign(socket, runtime: runtime, conditional: state)}
    end
  end

  def handle_event("validation", params, socket) do
    state = State.update(@validation, params)

    cond do
      not state.submitted ->
        {:noreply, assign(socket, validation: state)}

      state.answers["audience"] == "public" and state.answers["detail"] == "summary" ->
        # An external rule failed: return to the invalid item with its message.
        message = "Public answers need enough context. Choose a complete answer."
        {:noreply, assign(socket, validation: %{state | submitted: false, item: "detail", errors: %{"detail" => message}})}

      true ->
        {:noreply,
         assign(socket,
           validation: State.new(@validation),
           validation_result: "Saved: #{inspect(state.answers)}"
         )}
    end
  end
end
