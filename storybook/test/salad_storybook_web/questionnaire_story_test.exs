defmodule SaladStorybookWeb.QuestionnaireStoryTest do
  @moduledoc """
  Drives the server-driven questionnaire examples the way a browser without
  JavaScript would: every action is a submit button posting
  `_questionnaire[action]` with the form's current answers, and the LiveView
  re-renders the next step from `SaladUI.Questionnaire.State.update/2`.
  """
  use SaladStorybookWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  defp example(conn) do
    {:ok, view, _html} = live(conn, "/examples/questionnaire")
    [child] = live_children(view)
    child
  end

  defp press(view, form_id, action, answers \\ %{}) do
    view
    |> form("##{form_id}", answers)
    |> put_submitter(~s(button[name="_questionnaire[action]"][value="#{action}"]))
    |> render_submit()
  end

  defp active(view, form_id) do
    view
    |> element("##{form_id} fieldset[data-active]")
    |> render()
    |> Floki.parse_fragment!()
    |> Floki.attribute("data-name")
    |> List.first()
  end

  test "next validates on the server, then moves to the next item", %{conn: conn} do
    view = example(conn)
    assert active(view, "validation-questionnaire") == "detail"

    html = press(view, "validation-questionnaire", "next")
    assert active(view, "validation-questionnaire") == "detail"
    assert html =~ "Choose an answer to continue."
    assert has_element?(view, ~s(#validation-questionnaire fieldset[data-name="detail"][aria-invalid="true"]))

    press(view, "validation-questionnaire", "next", %{"detail" => ["summary"]})
    assert active(view, "validation-questionnaire") == "audience"
    refute has_element?(view, "#validation-questionnaire fieldset[aria-invalid]")
    # the earlier answer stays checked on the hidden item
    assert has_element?(view, ~s(#validation-questionnaire input[name="detail[]"][value="summary"][checked]))

    press(view, "validation-questionnaire", "previous")
    assert active(view, "validation-questionnaire") == "detail"
  end

  test "an external validator returns to the invalid item with its message", %{conn: conn} do
    view = example(conn)
    press(view, "validation-questionnaire", "next", %{"detail" => ["summary"]})

    html = press(view, "validation-questionnaire", "submit", %{"audience" => ["public"]})
    assert active(view, "validation-questionnaire") == "detail"
    assert html =~ "Public answers need enough context."

    press(view, "validation-questionnaire", "next", %{"detail" => ["complete"]})
    html = press(view, "validation-questionnaire", "submit")
    assert html =~ ~s(Saved: %{&quot;audience&quot; =&gt; &quot;public&quot;, &quot;detail&quot; =&gt; &quot;complete&quot;})
    assert active(view, "validation-questionnaire") == "detail"
  end

  test "conditional items join progress once an earlier answer enables them", %{conn: conn} do
    view = example(conn)
    assert render(view) =~ "Question 1 of 2"

    press(view, "conditional-questionnaire", "next", %{"runtime" => ["remote"]})
    assert active(view, "conditional-questionnaire") == "region"
    assert has_element?(view, "#conditional-questionnaire [data-slot=questionnaire-progress]", "Question 2 of 3")
  end

  test "navigation state: Next is disabled until the item is answered", %{conn: conn} do
    view = example(conn)
    assert has_element?(view, "#permission-questionnaire button[data-slot=questionnaire-next][disabled]")

    view
    |> form("#permission-questionnaire", %{"permission" => ["tests"]})
    |> render_change()

    refute has_element?(view, "#permission-questionnaire button[data-slot=questionnaire-next][disabled]")
  end
end
