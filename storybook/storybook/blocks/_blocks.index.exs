defmodule Storybook.Blocks.Index do
  @moduledoc false
  use PhoenixStorybook.Index

  def folder_name, do: "Blocks"
  def folder_open?, do: true

  def entry("dashboard_01"), do: [name: "Dashboard 01"]
  def entry("sidebar_07"), do: [name: "Sidebar 07"]
  def entry("login_03"), do: [name: "Login 03"]
  def entry("signup_03"), do: [name: "Signup 03"]
  def entry("chat_01"), do: [name: "Chat 01"]
end
