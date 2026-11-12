defmodule Storybook.SaladUIComponents.Typography do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.Typography

  def function, do: &Typography.typography_h1/1
  def layout, do: :one_column

  def imports,
    do: [
      {Typography,
       [
         typography_h2: 1,
         typography_h3: 1,
         typography_h4: 1,
         typography_p: 1,
         typography_blockquote: 1,
         typography_table: 1,
         typography_list: 1,
         typography_inline_code: 1,
         typography_lead: 1,
         typography_large: 1,
         typography_small: 1,
         typography_muted: 1
       ]}
    ]

  @table """
  <.typography_table>
    <thead>
      <tr>
        <th>King's Treasury</th>
        <th>People's happiness</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>Empty</td>
        <td>Overflowing</td>
      </tr>
      <tr>
        <td>Modest</td>
        <td>Satisfied</td>
      </tr>
      <tr>
        <td>Full</td>
        <td>Ecstatic</td>
      </tr>
    </tbody>
  </.typography_table>
  """

  @list """
  <.typography_list>
    <li>1st level of puns: 5 gold coins</li>
    <li>2nd level of jokes: 10 gold coins</li>
    <li>3rd level of one-liners : 20 gold coins</li>
  </.typography_list>
  """

  @quote """
  <.typography_blockquote>
    "After all," he said, "everyone enjoys a good joke, so it's only fair that they should pay for the privilege."
  </.typography_blockquote>
  """

  def variations do
    [
      %Variation{
        id: :demo,
        template: """
        <div>
          <.typography_h1>Taxing Laughter: The Joke Tax Chronicles</.typography_h1>
          <.typography_lead class="leading-7 [&:not(:first-child)]:mt-6">
            Once upon a time, in a far-off land, there was a very lazy king who spent all day lounging on his throne.
            One day, his advisors came to him with a problem: the kingdom was running out of money.
          </.typography_lead>
          <.typography_h2 class="mt-10">The King's Plan</.typography_h2>
          <.typography_p>
            The king thought long and hard, and finally came up with
            <a href="#" class="font-medium text-primary underline underline-offset-4">a brilliant plan</a>: he would tax the jokes in the kingdom.
          </.typography_p>
          #{@quote}
          <.typography_h3 class="mt-8">The Joke Tax</.typography_h3>
          <.typography_p>
            The king's subjects were not amused. They grumbled and complained, but the king was firm:
          </.typography_p>
          #{@list}
          <.typography_p>
            As a result, people stopped telling jokes, and the kingdom fell into a gloom. But there was one person who
            refused to let the king's foolishness get him down: a court jester named Jokester.
          </.typography_p>
          <.typography_h3 class="mt-8">Jokester's Revolt</.typography_h3>
          <.typography_p>
            Jokester began sneaking into the castle in the middle of the night and leaving jokes all over the place:
            under the king's pillow, in his soup, even in the royal toilet. The king was furious, but he couldn't seem
            to stop Jokester.
          </.typography_p>
          <.typography_p>
            And then, one day, the people of the kingdom discovered that the jokes left by Jokester were so funny that
            they couldn't help but laugh. And once they started laughing, they couldn't stop.
          </.typography_p>
          <.typography_h3 class="mt-8">The People's Rebellion</.typography_h3>
          <.typography_p>
            The people of the kingdom, feeling uplifted by the laughter, started to tell jokes and puns again, and soon
            the entire kingdom was in on the joke.
          </.typography_p>
          #{@table}
          <.typography_p>
            The king, seeing how much happier his subjects were, realized the error of his ways and repealed the joke
            tax. Jokester was declared a hero, and the kingdom lived happily ever after.
          </.typography_p>
          <.typography_p>
            The moral of the story is: never underestimate the power of a good laugh and always be careful of bad ideas.
          </.typography_p>
        </div>
        """
      },
      %Variation{
        id: :h1,
        template: """
        <.typography_h1 class="text-center">Taxing Laughter: The Joke Tax Chronicles</.typography_h1>
        """
      },
      %Variation{
        id: :h2,
        template: """
        <.typography_h2>The People of the Kingdom</.typography_h2>
        """
      },
      %Variation{
        id: :h3,
        template: """
        <.typography_h3>The Joke Tax</.typography_h3>
        """
      },
      %Variation{
        id: :h4,
        template: """
        <.typography_h4>People stopped telling jokes</.typography_h4>
        """
      },
      %Variation{
        id: :p,
        template: """
        <.typography_p>
          The king, seeing how much happier his subjects were, realized the error of his ways and repealed the joke tax.
        </.typography_p>
        """
      },
      %Variation{id: :blockquote, template: @quote},
      %Variation{id: :table, template: @table},
      %Variation{id: :list, template: @list},
      %Variation{
        id: :inline_code,
        template: """
        <.typography_inline_code>@radix-ui/react-alert-dialog</.typography_inline_code>
        """
      },
      %Variation{
        id: :lead,
        template: """
        <.typography_lead>
          A modal dialog that interrupts the user with important content and expects a response.
        </.typography_lead>
        """
      },
      %Variation{
        id: :large,
        template: """
        <.typography_large>Are you absolutely sure?</.typography_large>
        """
      },
      %Variation{
        id: :small,
        template: """
        <.typography_small>Email address</.typography_small>
        """
      },
      %Variation{
        id: :muted,
        template: """
        <.typography_muted>Enter your email address.</.typography_muted>
        """
      }
    ]
  end
end
