defmodule Synacor.Machine do
  @moduledoc """
  Functions to execute each operation type.
  """

  use Bitwise, only_operators: true

  import Integer, only: [mod: 2]

  alias Synacor.State

  @doc """
  halt: 0
  stop execution and terminate the program
  """
  def halt(%State{} = state) do
    Map.put(state, :halt, true)
  end

  @doc """
  set: 1 a b
  set register <a> to the value of <b>
  """
  def set_register(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val = Map.fetch!(memory, address + 2) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, val))
    |> Map.update!(:address, &(&1 + 3))
  end

  @doc """
  push: 2 a
  push <a> onto the stack
  """
  def push(%State{memory: memory, address: address} = state) do
    val = Map.fetch!(memory, address + 1) |> get_value(state.registers)

    state
    |> Map.update!(:stack, &[val | &1])
    |> Map.update!(:address, &(&1 + 2))
  end

  @doc """
  pop: 3 a
  remove the top element from the stack and write it into <a>; empty stack = error
  """
  def pop(%State{} = state) do
    dest = Map.fetch!(state.memory, state.address + 1) - 32768

    state
    |> Map.update!(:registers, &Map.put(&1, dest, hd(state.stack)))
    |> Map.update!(:stack, &tl/1)
    |> Map.update!(:address, &(&1 + 2))
  end

  @doc """
  eq: 4 a b c
  set <a> to 1 if <b> is equal to <c>; set it to 0 otherwise
  """
  def set_if_equals(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, if(val1 == val2, do: 1, else: 0)))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  gt: 5 a b c
  set <a> to 1 if <b> is greater than <c>; set it to 0 otherwise
  """
  def set_if_greater(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, if(val1 > val2, do: 1, else: 0)))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  jmp: 6 a
  jump to <a>
  """
  def jump_to(%State{memory: memory, address: address} = state) do
    val = Map.fetch!(memory, address + 1) |> get_value(state.registers)

    Map.put(state, :address, val)
  end

  @doc """
  jt: 7 a b
  if <a> is nonzero, jump to <b>
  """
  def jump_if_true(%State{memory: memory, address: address} = state) do
    val1 = Map.fetch!(memory, address + 1) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 2) |> get_value(state.registers)

    if val1 != 0 do
      Map.put(state, :address, val2)
    else
      Map.update!(state, :address, &(&1 + 3))
    end
  end

  @doc """
  jf: 8 a b
  if <a> is zero, jump to <b>
  """
  def jump_if_false(%State{memory: memory, address: address} = state) do
    val1 = Map.fetch!(memory, address + 1) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 2) |> get_value(state.registers)

    if val1 == 0 do
      Map.put(state, :address, val2)
    else
      Map.update!(state, :address, &(&1 + 3))
    end
  end

  @doc """
  add: 9 a b c
  assign into <a> the sum of <b> and <c> (modulo 32768)
  """
  def add(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, mod(val1 + val2, 32768)))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  mult: 10 a b c
  store into <a> the product of <b> and <c> (modulo 32768)
  """
  def multiply(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, mod(val1 * val2, 32768)))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  mod: 11 a b c
  store into <a> the remainder of <b> divided by <c>
  """
  def remainder(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, rem(val1, val2)))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  and: 12 a b c
  stores into <a> the bitwise and of <b> and <c>
  """
  def bitwise_and(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, val1 &&& val2))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  or: 13 a b c
  stores into <a> the bitwise or of <b> and <c>
  """
  def bitwise_or(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val1 = Map.fetch!(memory, address + 2) |> get_value(state.registers)
    val2 = Map.fetch!(memory, address + 3) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, val1 ||| val2))
    |> Map.update!(:address, &(&1 + 4))
  end

  @doc """
  not: 14 a b
  stores 15-bit bitwise inverse of <b> in <a>
  """
  def bitwise_inverse(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val = Map.fetch!(memory, address + 2) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, invert(val)))
    |> Map.update!(:address, &(&1 + 3))
  end

  defp invert(val) when is_integer(val) and val < 32768 do
    val
    |> Integer.to_string(2)
    |> String.pad_leading(15, "0")
    |> String.replace(["0", "1"], fn char -> if char == "0", do: "1", else: "0" end)
    |> String.to_integer(2)
  end

  @doc """
  rmem: 15 a b
  read memory at address <b> and write it to <a>
  """
  def read_memory(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768
    val = Map.fetch!(memory, address + 2) |> get_value(state.registers)

    state
    |> Map.update!(:registers, &Map.put(&1, dest, Map.fetch!(memory, val)))
    |> Map.update!(:address, &(&1 + 3))
  end

  @doc """
  wmem: 16 a b
  write the value from <b> into memory at address <a>
  """
  def write_memory(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) |> get_value(state.registers)
    val = Map.fetch!(memory, address + 2) |> get_value(state.registers)

    state
    |> Map.update!(:memory, &Map.put(&1, dest, val))
    |> Map.update!(:address, &(&1 + 3))
  end

  @doc """
  call: 17 a
  write the address of the next instruction to the stack and jump to <a>
  """
  def call(%State{memory: memory, address: address} = state) do
    val = Map.fetch!(memory, address + 1) |> get_value(state.registers)

    state
    |> Map.update!(:stack, &[address + 2 | &1])
    |> Map.put(:address, val)
  end

  @doc """
  ret: 18
  remove the top element from the stack and jump to it; empty stack = halt
  """
  def return(%State{stack: []} = state) do
    Map.put(state, :halt, true)
  end

  def return(%State{stack: [h | t], registers: registers} = state) do
    val = get_value(h, registers)

    state
    |> Map.put(:address, val)
    |> Map.put(:stack, t)
  end

  @doc """
  out: 19 a
  write the character represented by ascii code <a> to the terminal
  """
  def output(%State{memory: memory, address: address} = state) do
    val = Map.fetch!(memory, address + 1) |> get_value(state.registers)
    state = Map.update!(state, :address, &(&1 + 2))

    if val == 10 do
      IO.puts(state.output)
      Map.put(state, :output, [])
    else
      Map.update!(state, :output, &[&1, val])
    end
  end

  @doc """
  in: 20 a
  read a character from the terminal and write its ascii code to <a>; it can be
  assumed that once input starts, it will continue until a newline is
  encountered; this means that you can safely read whole lines from the keyboard
  and trust that they will be fully read
  """
  def input(%State{memory: memory, address: address} = state) do
    dest = Map.fetch!(memory, address + 1) - 32768

    [h | rest] =
      case state.input do
        [] -> IO.gets("> ") |> String.to_charlist()
        xs -> xs
      end

    state
    |> Map.update!(:registers, &Map.put(&1, dest, h))
    |> Map.put(:input, rest)
    |> Map.update!(:address, &(&1 + 2))
  end

  @doc """
  noop: 21
  no operation
  """
  def no_op(%State{} = state) do
    Map.update!(state, :address, &(&1 + 1))
  end

  defp get_value(number, registers) when number > 32767 and number < 32776 do
    Map.fetch!(registers, number - 32768)
  end

  defp get_value(number, _) when number < 32768, do: number
end
