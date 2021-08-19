defmodule Synacor.State do
  defstruct memory: nil,
            registers: %{0 => 0, 1 => 0, 2 => 0, 3 => 0, 4 => 0, 5 => 0, 6 => 0, 7 => 0},
            stack: [],
            address: 0,
            halt: false,
            output: []

  def init(attrs) do
    struct!(__MODULE__, attrs)
  end
end
