defmodule HRMInterpreter do

  # each command takes the current mem, an input, an output and optional val
  # then returns {new_mem, new_val, new_input, new_output}

  def command(:inbox, mem, input, output, _val \\ nil) do
    case input do
      [] -> {nil, []}
      [h | t] -> {mem, h, t, output}
    end
  end

  def command(:outbox, mem, input, output, val) do
    {mem, nil, input, output ++ [val]}
  end

  def command(:add, mem, input, output, val) do
    [v | new_mem] = mem
    new_val = v + val
    {new_mem, new_val, input, output ++ [new_val]} 
  end

  def command(:sub, mem, input, output, val) do
    [v | new_mem] = mem
    new_val = v - val
    {new_mem, new_val, input, output ++ [new_val]} 
  end
end

defmodule HRMApp do

  def inbox do
    HRMInterpreter.command(:inbox, [], [1,2,4], [])
  end

  def outbox do
    HRMInterpreter.command(:outbox, [], [1,2], [3], 4)
  end

  def add do
    HRMInterpreter.command(:add, [1,2,3], [], [], 3)
  end

  def subtract do
    HRMInterpreter.command(:sub, [4,3,2], [], [], 3)
  end

end
