defmodule SynacorTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  alias Synacor.{Machine, State}

  def state_fixture(program) do
    mem =
      program
      |> Enum.with_index(fn el, idx -> {idx, el} end)
      |> Map.new()

    %State{memory: mem}
  end

  test "halt/1" do
    s = state_fixture([0, 1, 2])
    res = Machine.halt(s)
    assert res.halt == true
  end

  test "set_register/1" do
    s = state_fixture([1, 32768, 123])
    res = Machine.set_register(s)
    assert res.registers[0] == 123
    assert res.address == 3
  end

  test "push/1" do
    s = state_fixture([2, 32768, 2, 100])
    res = Machine.push(s)
    assert res.stack == [0]
    assert res.address == 2
    res = Machine.push(res)
    assert res.stack == [100, 0]
    assert res.address == 4
  end

  test "pop/1" do
    s = state_fixture([3, 32772])
    s = Map.put(s, :stack, [123])
    res = Machine.pop(s)
    assert res.registers[4] == 123
    assert res.address == 2
    assert res.stack == []
  end

  test "set_if_equals/1" do
    s = state_fixture([4, 32768, 0, 32770])
    res = Machine.set_if_equals(s)
    assert res.registers[0] == 1
    assert res.address == 4

    s = state_fixture([4, 32768, 123, 32770])
    res = Machine.set_if_equals(s)
    assert res.registers[0] == 0
  end

  test "set_if_greater/1" do
    s = state_fixture([5, 32768, 1, 32770])
    res = Machine.set_if_greater(s)
    assert res.registers[0] == 1
    assert res.address == 4

    s = state_fixture([5, 32768, 32770, 2])
    res = Machine.set_if_greater(s)
    assert res.registers[0] == 0
  end

  test "jump_to/1" do
    s = state_fixture([6, 6, 0, 0, 0, 0, 6, 32768])
    res = Machine.jump_to(s)
    assert res.address == 6
    res = Machine.jump_to(res)
    assert res.address == 0
  end

  test "jump_if_true/1" do
    s = state_fixture([7, 2, 123])
    res = Machine.jump_if_true(s)
    assert res.address == 123

    s = state_fixture([7, 32768, 123])
    res = Machine.jump_if_true(s)
    assert res.address == 3
  end

  test "jump_if_false/1" do
    s = state_fixture([8, 32768, 123])
    res = Machine.jump_if_false(s)
    assert res.address == 123

    s = state_fixture([8, 2, 123])
    res = Machine.jump_if_false(s)
    assert res.address == 3
  end

  test "add/1" do
    s = state_fixture([9, 32768, 123, 32770])
    res = Machine.add(s)
    assert res.registers[0] == 123

    s = state_fixture([9, 32769, 32766, 4])
    res = Machine.add(s)
    assert res.registers[1] == 2
    assert res.address == 4
  end

  test "multiply/1" do
    s = state_fixture([10, 32768, 328, 100])
    res = Machine.multiply(s)
    assert res.registers[0] == 32

    s = state_fixture([10, 32769, 32770, 999])
    res = Machine.multiply(s)
    assert res.registers[1] == 0
    assert res.address == 4
  end

  test "remainder/1" do
    s = state_fixture([11, 32768, 10, 3])
    res = Machine.remainder(s)
    assert res.registers[0] == 1
    assert res.address == 4
  end

  test "bitwise_and/1" do
    s = state_fixture([12, 32768, 12, 150])
    res = Machine.bitwise_and(s)
    assert res.registers[0] == 4

    s = state_fixture([12, 32768, 12, 32770])
    res = Machine.bitwise_and(s)
    assert res.registers[0] == 0
    assert res.address == 4
  end

  test "bitwise_or/1" do
    s = state_fixture([13, 32768, 12, 150])
    res = Machine.bitwise_or(s)
    assert res.registers[0] == 158

    s = state_fixture([13, 32768, 12, 32770])
    res = Machine.bitwise_or(s)
    assert res.registers[0] == 12
    assert res.address == 4
  end

  test "bitwise_inverse/1" do
    s = state_fixture([14, 32768, 3456])
    res = Machine.bitwise_inverse(s)
    assert res.registers[0] == 29311
    assert res.address == 3
  end

  test "read_memory/1" do
    s = state_fixture([15, 32768, 3, 9])
    res = Machine.read_memory(s)
    assert res.registers[0] == 9
    assert res.address == 3
  end

  test "write_memory/1" do
    s = state_fixture([16, 0, 999])
    res = Machine.write_memory(s)
    assert res.memory == %{0 => 999, 1 => 0, 2 => 999}
    assert res.address == 3

    s = state_fixture([16, 32770, 999])
    res = Machine.write_memory(s)
    assert res.memory == %{0 => 999, 1 => 32770, 2 => 999}
  end

  test "call/1" do
    s = state_fixture([17, 999])
    res = Machine.call(s)
    assert res.stack == [2]
    assert res.address == 999

    s = state_fixture([17, 32768])
    res = Machine.call(s)
    assert res.stack == [2]
    assert res.address == 0
  end

  test "return/1" do
    s = state_fixture([18, 0])
    s = Map.put(s, :stack, [10])
    res = Machine.return(s)
    assert res.address == 10
    assert res.stack == []

    s = Map.put(s, :stack, [32768])
    res = Machine.return(s)
    assert res.address == 0
    assert res.stack == []
  end

  test "output/1" do
    s = state_fixture([19, 97, 19, 32770, 19, 10])
    s = Map.update!(s, :registers, &Map.put(&1, 2, 99))
    res = Machine.output(s)
    assert res.output == [[], 97]
    assert res.address == 2

    res = Machine.output(res)
    assert res.output == [[[], 97], 99]
    assert res.address == 4

    assert capture_io(fn -> Machine.output(res) end) == "ac\n"
  end

  test "no_op/1" do
    s = state_fixture([21, 21, 21, 21, 21])
    res = Machine.no_op(s)
    assert Map.put(s, :address, 1) == res
    res = Machine.no_op(res)
    assert Map.put(s, :address, 2) == res
  end
end
