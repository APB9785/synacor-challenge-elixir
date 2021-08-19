defmodule Synacor.Interpreter do
  alias Synacor.{Machine, State}

  def run(path) do
    mem = init_mem(path)

    %{memory: mem}
    |> State.init()
    |> loop()
  end

  def loop(%State{halt: true}), do: IO.puts("Halt")

  def loop(%State{} = state) do
    case Map.get(state.memory, state.address) do
      0 -> Machine.halt(state) |> loop()
      1 -> Machine.set_register(state) |> loop()
      2 -> Machine.push(state) |> loop()
      3 -> Machine.pop(state) |> loop()
      4 -> Machine.set_if_equals(state) |> loop()
      5 -> Machine.set_if_greater(state) |> loop()
      6 -> Machine.jump_to(state) |> loop()
      7 -> Machine.jump_if_true(state) |> loop()
      8 -> Machine.jump_if_false(state) |> loop()
      9 -> Machine.add(state) |> loop()
      10 -> Machine.multiply(state) |> loop()
      11 -> Machine.remainder(state) |> loop()
      12 -> Machine.bitwise_and(state) |> loop()
      13 -> Machine.bitwise_or(state) |> loop()
      14 -> Machine.bitwise_inverse(state) |> loop()
      15 -> Machine.read_memory(state) |> loop()
      16 -> Machine.write_memory(state) |> loop()
      17 -> Machine.call(state) |> loop()
      18 -> Machine.return(state) |> loop()
      19 -> Machine.output(state) |> loop()
      20 -> Machine.input(state) |> loop()
      21 -> Machine.no_op(state) |> loop()
    end
  end

  def init_mem(path) do
    path
    |> File.read!()
    |> decompile()
    |> Enum.with_index(fn el, idx -> {idx, el} end)
    |> Map.new()
  end

  def decompile(binary), do: decompile(binary, [])

  defp decompile("", done), do: Enum.reverse(done)

  defp decompile(todo, done) do
    <<first::8, second::8, rest::binary>> = todo
    <<little::16>> = <<second, first>>
    decompile(rest, [little | done])
  end
end
