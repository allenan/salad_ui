defmodule Storybook.SaladUIComponents.Table do
  @moduledoc false
  use PhoenixStorybook.Story, :component

  alias SaladUI.DropdownMenu
  alias SaladUI.Table

  def function, do: &Table.table/1
  def layout, do: :one_column

  def imports,
    do: [
      {Table,
       [table_caption: 1, table_header: 1, table_row: 1, table_head: 1, table_body: 1, table_cell: 1, table_footer: 1]},
      {DropdownMenu,
       [dropdown_menu_trigger: 1, dropdown_menu_content: 1, dropdown_menu_item: 1, dropdown_menu_separator: 1]},
      {SaladUI.Button, [button: 1]},
      {SaladUI.Checkbox, [checkbox: 1]},
      {SaladUI.Helpers, [as_child: 1]}
    ]

  @invoices ~s([
    {"INV001", "Paid", "Credit Card", "$250.00"},
    {"INV002", "Pending", "PayPal", "$150.00"},
    {"INV003", "Unpaid", "Bank Transfer", "$350.00"},
    {"INV004", "Paid", "Credit Card", "$450.00"},
    {"INV005", "Paid", "PayPal", "$550.00"},
    {"INV006", "Pending", "Bank Transfer", "$200.00"},
    {"INV007", "Unpaid", "Credit Card", "$300.00"}
  ])

  def variations do
    [
      %Variation{
        id: :table_demo,
        description: "shadcn table-demo.",
        template: """
        <.table>
          <.table_caption>A list of your recent invoices.</.table_caption>
          <.table_header>
            <.table_row>
              <.table_head class="w-[100px]">Invoice</.table_head>
              <.table_head>Status</.table_head>
              <.table_head>Method</.table_head>
              <.table_head class="text-right">Amount</.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
            <.table_row :for={{invoice, status, method, amount} <- #{@invoices}}>
              <.table_cell class="font-medium">{invoice}</.table_cell>
              <.table_cell>{status}</.table_cell>
              <.table_cell>{method}</.table_cell>
              <.table_cell class="text-right">{amount}</.table_cell>
            </.table_row>
          </.table_body>
          <.table_footer>
            <.table_row>
              <.table_cell colspan="3">Total</.table_cell>
              <.table_cell class="text-right">$2,500.00</.table_cell>
            </.table_row>
          </.table_footer>
        </.table>
        """
      },
      %Variation{
        id: :table_footer,
        description: "shadcn table-footer: a `table_footer` for totals.",
        template: """
        <.table>
          <.table_caption>A list of your recent invoices.</.table_caption>
          <.table_header>
            <.table_row>
              <.table_head class="w-[100px]">Invoice</.table_head>
              <.table_head>Status</.table_head>
              <.table_head>Method</.table_head>
              <.table_head class="text-right">Amount</.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
            <.table_row :for={{invoice, status, method, amount} <- Enum.take(#{@invoices}, 3)}>
              <.table_cell class="font-medium">{invoice}</.table_cell>
              <.table_cell>{status}</.table_cell>
              <.table_cell>{method}</.table_cell>
              <.table_cell class="text-right">{amount}</.table_cell>
            </.table_row>
          </.table_body>
          <.table_footer>
            <.table_row>
              <.table_cell colspan="3">Total</.table_cell>
              <.table_cell class="text-right">$2,500.00</.table_cell>
            </.table_row>
          </.table_footer>
        </.table>
        """
      },
      %Variation{
        id: :table_actions,
        description: "shadcn table-actions: a dropdown menu of row actions.",
        template: """
        <.table>
          <.table_header>
            <.table_row>
              <.table_head>Product</.table_head>
              <.table_head>Price</.table_head>
              <.table_head class="text-right">Actions</.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
            <.table_row :for={{id, product, price} <- [{"mouse", "Wireless Mouse", "$29.99"}, {"keyboard", "Mechanical Keyboard", "$129.99"}, {"hub", "USB-C Hub", "$49.99"}]}>
              <.table_cell class="font-medium">{product}</.table_cell>
              <.table_cell>{price}</.table_cell>
              <.table_cell class="text-right">
                <SaladUI.DropdownMenu.dropdown_menu id={"table-actions-" <> id}>
                  <.as_child tag={&dropdown_menu_trigger/1} child={&button/1} variant="ghost" size="icon" class="size-8">
                    <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
                      <circle cx="12" cy="12" r="1" />
                      <circle cx="19" cy="12" r="1" />
                      <circle cx="5" cy="12" r="1" />
                    </svg>
                    <span class="sr-only">Open menu</span>
                  </.as_child>
                  <.dropdown_menu_content align="end">
                    <.dropdown_menu_item>Edit</.dropdown_menu_item>
                    <.dropdown_menu_item>Duplicate</.dropdown_menu_item>
                    <.dropdown_menu_separator />
                    <.dropdown_menu_item variant="destructive">Delete</.dropdown_menu_item>
                  </.dropdown_menu_content>
                </SaladUI.DropdownMenu.dropdown_menu>
              </.table_cell>
            </.table_row>
          </.table_body>
        </.table>
        """
      },
      %Variation{
        id: :table_selection,
        description:
          "Rows with `checkbox/1`: the cell drops its right padding and nudges the native checkbox down 2px, like shadcn's Radix checkbox.",
        template: """
        <.table>
          <.table_header>
            <.table_row>
              <.table_head><.checkbox id="table-select-all" aria-label="Select all" /></.table_head>
              <.table_head>Product</.table_head>
              <.table_head class="text-right">Price</.table_head>
            </.table_row>
          </.table_header>
          <.table_body>
            <.table_row :for={{id, product, price} <- [{"mouse", "Wireless Mouse", "$29.99"}, {"keyboard", "Mechanical Keyboard", "$129.99"}]} data-state={id == "mouse" && "selected"}>
              <.table_cell><.checkbox id={"table-select-" <> id} checked={id == "mouse"} aria-label="Select row" /></.table_cell>
              <.table_cell class="font-medium">{product}</.table_cell>
              <.table_cell class="text-right">{price}</.table_cell>
            </.table_row>
          </.table_body>
        </.table>
        """
      }
    ]
  end
end
