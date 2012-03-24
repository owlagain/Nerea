require("os")
require("socket")

-----------------------------------------------------------------------------------------------------------------------
-- Support functions
-----------------------------------------------------------------------------------------------------------------------

-- 50/50 randomizer, as a result returns true or false with 50% probability

function Answer()
  local Value = math.random(1, 100)
  if Value <= 50 then
    return(true)
  else
    return(false)
  end
end

-- Radius-randomizer function, returns random value within set radius: from -radius to +radius

function Random(Radius)
  return(2.0 * (math.random()) * Radius - Radius)
end

-- Sigma function for neuron output

function Sigma(Slope, Argument)
  return(math.tanh(Slope * Argument))
end

-- Standart deviation normalization function

function Root(Values)
  local i = nil
  local Norma = 0.0
  for i = 1, table.getn(Values) do
    Norma = Norma + math.pow(Values[i], 2)
  end
  Norma = math.sqrt(Norma);
  if Norma == 0.0 then
    Norma = 1.0
  end
  for i = 1, table.getn(Values) do
    Values[i] = Values[i] / Norma
  end
  return(Norma)
end

-- Standart deviation reverse normalization function

function Square(Values, Norma)
  local i = nil
  for i = 1, table.getn(Values) do
    Values[i] = Values[i] * Norma;
  end
end

-- Function that returns count of units in the next population based on count of units in current one

function Population(Population)
  return((Population * (Population - 1)) / 2.0)
end

-- Crosses two values

function Cross(ValueA, ValueB, Mutation)
  local Value = nil
  if Answer() == true then
    if Answer() == true then
      Value = ValueA
    else
      Value = ValueB
    end
  else
    Value = (ValueA + ValueB) / 2.0
  end
  if Answer() == true then
    Value = Value + Random(Mutation)
  end
  return(Value)
end

-- Sorts Networks by Training Error

function Sort(Networks)
  local Maximum = nil
  local Indexes = nil
  local Minimum = nil
  local Index = nil
  Maximum = 0.0
  Indexes = {}
  for i = 1, table.getn(Networks) do
    Minimum = 0.0
    Index = nil
    for i = 1, table.getn(Networks) do
      if Networks[i].Results.Error > Minimum then
        Minimum = Networks[i].Results.Error
        Index = i
      end
    end
    for i = 1, table.getn(Networks) do
      if Networks[i].Results.Error < Minimum and Networks[i].Results.Error > Maximum then
        Minimum = Networks[i].Results.Error
        Index = i
      end
    end
    Maximum = Minimum
    table.insert(Indexes, Index)
  end
  return(Indexes)
end

-- This function simply clones table

function Clone(Table)
  local Index = nil
  local Value = nil
  local Clone = nil
  Clone = {}
  for Index, Value in pairs(Table) do
    Clone[Index] = Value
  end
  return(Clone)
end

-- Returns available sequence count and data offset

function Subsequence(ValueCount, InputCount, OutputCount, Frame)
  local Count = nil
  local Offset = nil
  Count = 1 + math.floor((ValueCount - (InputCount + OutputCount)) / Frame)
  if Count < 0 then
    Count = 0
  end
  Offset = ValueCount - ((Count - 1) * Frame + (InputCount + OutputCount))
  if Offset < 0 then
    Offset = 0
  end
  return Count, Offset
end

-- Trims string

function Trim(String)
  return(String:gsub("^%s*(.-)%s*$", "%1"))
end

-- Cleans file

function Clean(Path)
  local File = nil
  File = io.open(Path, "w")
  File:close()
end

-- Writes string to file

function Write(Path, String)
  local File = nil
  File = io.open(Path, "a")
  File:write(String.."\n")
  File:close()
end

-----------------------------------------------------------------------------------------------------------------------
-- Nerea Class Synapse
-----------------------------------------------------------------------------------------------------------------------

NC_Synapse = {}
NC_Synapse.__index = NC_Synapse

function NC_Synapse.New(Layer, Neuron, Weight)
  local Synapse = nil
  Synapse = {}
  setmetatable(Synapse, NC_Synapse)
  Synapse.Layer = Layer
  Synapse.Neuron = Neuron
  Synapse.Weight = Weight
  return(Synapse)
end

function NC_Synapse:Clone()
  return(NC_Synapse.New(self.Layer, self.Neuron, self.Weight))
end

function NC_Synapse:Copy(Synapse)
  self.Layer = Synapse.Layer
  self.Neuron = Synapse.Neuron
  self.Weight = Synapse.Weight
end

function NC_Synapse:Init(Init)
  self.Weight = Random(Init)
end

function NC_Synapse:Cross(SynapseA, SynapseB, Mutation)
  self.Weight = Cross(SynapseA.Weight, SynapseB.Weight, Mutation)
end


-----------------------------------------------------------------------------------------------------------------------
-- Nerea Class Neuron
-----------------------------------------------------------------------------------------------------------------------

NC_Neuron = {}
NC_Neuron.__index = NC_Neuron

function NC_Neuron.New()
  local Neuron = nil
  Neuron = {}
  setmetatable(Neuron, NC_Neuron)
  Neuron.Synapses = {}
  Neuron.Bias = 0.0
  Neuron.Axon = 0.0
  return(Neuron)
end

function NC_Neuron:Load(File)
  local String = nil
  local Split = nil
  local Values = nil
  while true do
    String = File:read("*line")
    if String == nil then
      break
    end
    String = Trim(String)
    if String == "</Neuron>" then
      break
    end
    Values = {}
    for Split in string.gmatch(String, "%S+") do
      table.insert(Values, Split)
    end
    if Values[1] == "Synapse" then
      self:AddSynapse(tonumber(Values[2]), tonumber(Values[3]), tonumber(Values[4]))
    elseif Values[1] == "Bias" then
      self.Bias = tonumber(Values[2])
    end
  end
end

function NC_Neuron:Save(Path)
  local i = nil
  if table.getn(self.Synapses) == 0 and self.Bias == 0.0 then
    Write(Path, "\t\t<Neuron/>")
  else
    Write(Path, "\t\t<Neuron>")
    for i = 1, table.getn(self.Synapses) do
      Write(Path, "\t\t\tSynapse\t"..self.Synapses[i].Layer.."\t"..self.Synapses[i].Neuron.."\t"..self.Synapses[i].Weight)
    end
    Write(Path, "\t\t\tBias\t"..self.Bias)
    Write(Path, "\t\t</Neuron>")
  end
end

function NC_Neuron:AddSynapse(LayerIndex, NeuronIndex, Weight)
  table.insert(self.Synapses, NC_Synapse.New(LayerIndex, NeuronIndex, Weight))
end

function NC_Neuron:Clone()
  local Neuron = nil
  local i = nil
  Neuron = NC_Neuron.New()
  for i = 1, table.getn(self.Synapses) do
    table.insert(Neuron.Synapses, self.Synapses[i]:Clone())
  end
  Neuron.Bias = self.Bias
  Neuron.Axon = self.Axon
  return(Neuron)
end

function NC_Neuron:Copy(Neuron)
  local i = nil
  for i = 1, table.getn(self.Synapses) do
    self.Synapses[i]:Copy(Neuron.Synapses[i])
  end
  self.Bias = Neuron.Bias
  self.Axon = Neuron.Axon
end

function NC_Neuron:Init(Init)
  local i = nil
  for i = 1, table.getn(self.Synapses) do
    self.Synapses[i]:Init(Init)
  end
  self.Bias = Random(Init)
end

function NC_Neuron:Shock()
  self.Axon = 0.0
end

function NC_Neuron:Process(Network)
  local i = nil
  local Value = nil
  Value = 0.0
  for i = 1, table.getn(self.Synapses) do
    Value = Value + self.Synapses[i].Weight * Network.Layers[self.Synapses[i].Layer].Neurons[self.Synapses[i].Neuron].Axon
  end
  Value = Value + self.Bias * Network.Parameters.Bias
  Value = Sigma(Network.Parameters.Slope, Value)
  self.Axon = Value
end

function NC_Neuron:Cross(NeuronA, NeuronB, Mutation)
  local i = nil
  for i = 1, table.getn(self.Synapses) do
    self.Synapses[i]:Cross(NeuronA.Synapses[i], NeuronB.Synapses[i], Mutation)
  end
  self.Bias = Cross(NeuronA.Bias, NeuronB.Bias, Mutation)      
end


-----------------------------------------------------------------------------------------------------------------------
-- Nerea Class Layer
-----------------------------------------------------------------------------------------------------------------------

NC_Layer = {}
NC_Layer.__index = NC_Layer

function NC_Layer.New()
  local Layer = nil
  Layer = {}
  setmetatable(Layer, NC_Layer)
  Layer.Neurons = {}
  return(Layer)
end

function NC_Layer:Load(File)
  local String = nil
  while true do
    String = File:read("*line")
    if String == nil then
      break
    end
    String = Trim(String)
    if String == "</Layer>" then
      break
    elseif String == "<Neuron/>" then
      self:AddNeuron()
    elseif String == "<Neuron>" then
      self:AddNeuron()
      self.Neurons[table.getn(self.Neurons)]:Load(File)
    end
  end
end

function NC_Layer:Save(Path)
  local i = nil
  Write(Path, "\t<Layer>")
  for i = 1, table.getn(self.Neurons) do
    self.Neurons[i]:Save(Path)
  end
  Write(Path, "\t</Layer>")
end

function NC_Layer:AddNeuron()
  table.insert(self.Neurons, NC_Neuron.New())
end

function NC_Layer:Clone()
  local Layer = nil
  local i = nil
  Layer = NC_Layer.New()
  for i = 1, table.getn(self.Neurons) do
    table.insert(Layer.Neurons, self.Neurons[i]:Clone())
  end
  return(Layer)
end

function NC_Layer:Copy(Layer)
  local i = nil
  for i = 1, table.getn(self.Neurons) do
    self.Neurons[i]:Copy(Layer.Neurons[i])
  end
end

function NC_Layer:Init(Init)
  local i = nil
  for i = 1, table.getn(self.Neurons) do
    self.Neurons[i]:Init(Init)
  end
end

function NC_Layer:Shock()
  local i = nil
  for i = 1, table.getn(self.Neurons) do
    self.Neurons[i]:Shock()
  end
end

function NC_Layer:Process(Network)
  local i = nil
  for i = 1, table.getn(self.Neurons) do
    self.Neurons[i]:Process(Network)
  end
end

function NC_Layer:Cross(LayerA, LayerB, Mutation)
  local i = nil
  for i = 1, table.getn(self.Neurons) do
    self.Neurons[i]:Cross(LayerA.Neurons[i], LayerB.Neurons[i], Mutation)
  end
end


-----------------------------------------------------------------------------------------------------------------------
-- Nerea Class Network
-----------------------------------------------------------------------------------------------------------------------

NC_Network = {}
NC_Network.__index = NC_Network

function NC_Network.New()
  local Network = nil
  Network = {}
  setmetatable(Network, NC_Network)
  Network.Parameters = {}
  Network.Layers = {}
  Network.Results = {}
  return(Network)
end

function NC_Network:Load(Path)
  local File = nil
  local String = nil
  local Values = nil
  File = io.open(Path, "r")
  if File ~= nil then
    while true do
      String = File:read("*line")
      if String == nil then
        break
      end
      String = Trim(String)
      if String == "<Parameters>" then
        while true do
          String = File:read("*line")
          if String == nil then
            break
          end
          String = Trim(String)
          if String == "</Parameters>" then
            break
          end
          Values = {}
          for Split in string.gmatch(String, "%S+") do
            table.insert(Values, Split)
          end
          self.Parameters[Values[1]] = tonumber(Values[2])
        end
      elseif String == "<Topology>" then
        while true do
          String = File:read("*line")
          if String == nil then
            break
          end
          String = Trim(String)
          if String == "</Topology>" then
            break
          elseif String == "<Layer>" then
            self:AddLayer()
            self.Layers[table.getn(self.Layers)]:Load(File)
          end
        end
      elseif String == "<Results>" then
        while true do
          String = File:read("*line")
          if String == nil then
            break
          end
          String = Trim(String)
          if String == "</Results>" then
            break
          end
          Values = {}
          for Split in string.gmatch(String, "%S+") do
            table.insert(Values, Split)
          end
          self.Results[Values[1]] = tonumber(Values[2])
        end      
      end
    end
    File:close()
    self.Results.InputCount = table.getn(self.Layers[1].Neurons)
    self.Results.OutputCount = table.getn(self.Layers[table.getn(self.Layers)].Neurons)
  end
end

function NC_Network:Save(Path)
  local i = nil
  local Index = nil
  local Value = nil
  Clean(Path)
  Write(Path, "<Parameters>")
  for Index, Value in pairs(self.Parameters) do
    Write(Path, "\t"..Index.."\t"..Value)
  end
  Write(Path, "</Parameters>")
  Write(Path, "<Topology>")
  for i = 1, table.getn(self.Layers) do
    self.Layers[i]:Save(Path)
  end
  Write(Path, "</Topology>")
  Write(Path, "<Results>")
  for Index, Value in pairs(self.Results) do
    Write(Path, "\t"..Index.."\t"..Value)
  end
  Write(Path, "</Results>")
end

function NC_Network:AddLayer()
  table.insert(self.Layers, NC_Layer.New())
end

function NC_Network:Clone()
  local i = nil
  local Network = nil
  Network = NC_Network.New()
  Network.Parameters = Clone(self.Parameters)
  Network.Layers = {}
  for i = 1, table.getn(self.Layers) do
    table.insert(Network.Layers, self.Layers[i]:Clone())
  end
  Network.Results = Clone(self.Results)
  return(Network)
end

function NC_Network:Copy(Network)
  local i = nil
  self.Parameters = Clone(Network.Parameters)
  for i = 1, table.getn(self.Layers) do
    self.Layers[i]:Copy(Network.Layers[i])
  end
  self.Results = Clone(Network.Results)
end

function NC_Network:Init()
  local i = nil
  for i = 2, table.getn(self.Layers) do
    self.Layers[i]:Init(self.Parameters.Init)
  end
end

function NC_Network:Shock()
  local i = nil
  for i = 1, table.getn(self.Layers) do
    self.Layers[i]:Shock()
  end
end

function NC_Network:Forget()
  self.Results.Generation = 0
  self.Results.Examples = 0
  self.Results.Error = 0.0
end

function NC_Network:Process(Values)
  local i = nil
  local Input = nil
  local Norma = nil
  local Output = nil
  -- Prepare input values for normalization
  Input = {}
  for i = 1, self.Results.InputCount do
    table.insert(Input, Values[i])
  end
  -- Normalize input values
  if self.Parameters.Normalization == 1 then
    Norma = Root(Input)
  end
  -- Pass input values to input layer
  for i = 1, self.Results.InputCount do
    self.Layers[1].Neurons[i].Axon = Input[i]
  end
  -- Process values
  for i = 2, table.getn(self.Layers) do
    self.Layers[i]:Process(self)
  end
  -- Collect output values from output layer
  Output = {}
  for i = 1, self.Results.OutputCount do
    table.insert(Output, self.Layers[table.getn(self.Layers)].Neurons[i].Axon)
  end
  -- Revert output values' normalization
  if self.Parameters.Normalization == 1 then
    Square(Output, Norma)
  end
  return(Output)
end

function NC_Network:Cross(NetworkA, NetworkB)
  local i = nil
  for i = 2, table.getn(self.Layers) do
    self.Layers[i]:Cross(NetworkA.Layers[i], NetworkB.Layers[i], self.Parameters.Mutation)
  end
end

function NC_Network:Learn(Values)
  local i = nil
  local Output = nil
  local Error = nil
  Output = self:Process(Values)
  Error = 0.0
  for i = 1, self.Results.OutputCount do
    Error = Error + math.abs(Values[self.Results.InputCount + i] - Output[i])
  end
  Error = Error / self.Results.OutputCount
  self.Results.Error = self.Results.Examples * self.Results.Error
  self.Results.Error = self.Results.Error + Error
  self.Results.Examples = self.Results.Examples + 1
  self.Results.Error = self.Results.Error / self.Results.Examples
end

function NC_Network:Teach(Data)
  local i, j, k = nil
  local Generation = nil
  local Indexes = {}
  local Initial = {}
  local Crossed = {}
  local Mixed = {}
  -- Create Initial population
  self:Shock()
  self:Forget()
  self:Init()
  for i = 1, self.Parameters.Population do
    table.insert(Initial, self:Clone())
    Initial[i]:Init()
  end
  -- Create Crossed population based on Initial
  for i = 1, Population(self.Parameters.Population) do
    table.insert(Crossed, self:Clone())
    Crossed[i]:Init()
  end
  -- Create Mixed population (using if Incest parameter is on) based on Initial
  for i = 1, self.Parameters.Population + Population(self.Parameters.Population) do
    table.insert(Mixed, self:Clone())
    Mixed[i]:Init()   
  end
  -- Teach Initial population
  for i = 1, table.getn(Initial) do
    for j = 1, Data.FeedCount do
      Initial[i]:Learn(Data.Feeds[j])
    end
  end
  -- Print first generation results
  Indexes = Sort(Initial)
  Generation = 1
  if Generation % self.Parameters.Print == 0 then
    print(Generation, Initial[Indexes[1]].Results.Error)
  end
  -- Teaching cycle
  repeat
    -- Cross Initial's population units
    i = 1
    for j = 1, table.getn(Initial) do
      for k = j + 1, table.getn(Initial) do
        Crossed[i]:Cross(Initial[j], Initial[k])
        i = i + 1
      end
    end
    -- Teach Cross population
    for i = 1, table.getn(Crossed) do
      Crossed[i]:Shock()
      Crossed[i]:Forget()
      for j = 1, Data.FeedCount do
        Crossed[i]:Learn(Data.Feeds[j])
      end
    end
    -- Population's evolution
    if self.Parameters.Incest == 1 then
      for i = 1, table.getn(Initial) do
        Mixed[i]:Copy(Initial[i])
      end
      for i = 1, table.getn(Crossed) do
        Mixed[table.getn(Initial) + i]:Copy(Crossed[i])
      end
      Indexes = Sort(Mixed)
      for i = 1, table.getn(Initial) do
        Initial[i]:Copy(Mixed[Indexes[i]])
      end
    else
      Indexes = Sort(Crossed)
      for i = 1, table.getn(Initial) do
        Initial[i]:Copy(Crossed[Indexes[i]])
      end
    end
    -- Print current generation results
    Generation = Generation + 1
    if Generation % self.Parameters.Print == 0 then
      print(Generation, Initial[1].Results.Error)
    end
  until Initial[1].Results.Error < self.Parameters.Error or Generation >= self.Parameters.Generations
  -- Copy teached Network with best results to itself
  self:Copy(Initial[1])
  self.Results.Generation = Generation
  print(self.Results.Generation, self.Results.Error)
end

function NC_Network:Work(Data)
  local i, j = nil
  local Output = nil
  local Raw = nil
  local Feed = nil
  local Results = nil
  local Count = nil
  local FeedCount = nil
  local Offset = nil
  local Length = nil
  self:Shock()
  Raw = {}
  for i = 1, Data.FeedCount do
    Output = self:Process(Data.Feeds[i])
    for j = 1, self.Results.OutputCount do
      table.insert(Raw, Output[j])
    end
  end
  for i = 1, self.Parameters.Predictions do
    Feed = {}
    RawCount = table.getn(Raw)
    for j = 1 + RawCount - self.Results.InputCount, RawCount do
      table.insert(Feed, Raw[j])
    end
    Output = self:Process(Feed)
    for j = 1, self.Results.OutputCount do
      table.insert(Raw, Output[j])
    end    
  end
  RawCount = table.getn(Raw)
  Results = NC_Data.New()
  FeedCount = math.floor(RawCount / self.Parameters.Columns)
  Remainder = RawCount - self.Parameters.Columns * FeedCount
  for i = 1, FeedCount do
    Feed = {}
    for j = 1 + (i - 1) * self.Parameters.Columns, i * self.Parameters.Columns do
      table.insert(Feed, Raw[j])
    end
    Results:AddFeed(Feed)
  end
  Feed = {}
  for i = 1 + RawCount - Remainder, RawCount do
    table.insert(Feed, Raw[i])
  end
  Results:AddFeed(Feed)
  return(Results)
end


-----------------------------------------------------------------------------------------------------------------------
-- Nerea Class Data
-----------------------------------------------------------------------------------------------------------------------

NC_Data = {}
NC_Data.__index = NC_Data

function NC_Data.New()
  local Data = nil
  Data = {}
  setmetatable(Data, NC_Data)
  Data.FeedCount = 0
  Data.Feeds = {}
  return(Data)
end

function NC_Data:AddFeed(Values)
  table.insert(self.Feeds, Values)
  self.FeedCount = self.FeedCount + 1
end

function NC_Data:Load(Path, InputCount, OutputCount, Frame)
  local i, j = nil
  local File = nil
  local Values = nil
  local String = nil
  local ValueCount = nil
  local Count = nil
  local Offset = nil
  local Length = nil
  local Feed = nil
  File = io.open(Path, "r")
  if File ~= nil then
    Values = {}
    while true do
      String = File:read("*line")
      if String == nil then
        break
      end
      for Split in string.gmatch(String, "%S+") do
        table.insert(Values, tonumber(Split))
      end
    end
    ValueCount = table.getn(Values)
    Count, Offset = Subsequence(ValueCount, InputCount, OutputCount, Frame)
    Length = InputCount + OutputCount
    for i = 1, Count do
      Feed = {}
      for j = 1 + Offset + (i - 1) * Frame, Offset + (i - 1) * Frame + Length do
        table.insert(Feed, Values[j])
      end
      self:AddFeed(Feed)
    end
    File:close()
  end
end

function NC_Data:Save(Path)
  local i, j = nil
  local File = nil
  local Feed = nil
  File = io.open(Path, "w")
  if File ~= nil then
    for i = 1, self.FeedCount do
      Feed = ""
      for j = 1, table.getn(self.Feeds[i]) do
        if j == 1 then
          Feed = Feed..self.Feeds[i][j]
        else
          Feed = Feed.." "..self.Feeds[i][j]
        end
      end
      Feed = Feed.."\n"
      File:write(Feed)
    end
    File:close()
  end
end


-----------------------------------------------------------------------------------------------------------------------
-- Main function
-----------------------------------------------------------------------------------------------------------------------

local function Main()
  local Network = nil
  local Data = nil
  local Results = nil
  local Log = nil
  local Seconds = nil
  local Hours = nil
  local Minutes = nil
  local String = nil
  Seconds = os.time()
  Log = "./Log.txt"
  String = "# Launched: "..os.date("%c").." -"
  for i = 0, #arg do
    String = String.." "..arg[i]
  end
  Write(Log, String)
  math.randomseed(os.time())
  if #arg ~= 4 then
    Write(Log, "# Usage: lua ./Nerea.lua <-T | -W> <Network> <Data> <Network | Results>")
  else
    if arg[1] == "-T" then
      Network = NC_Network.New()
      Network:Load(arg[2])
      Data = NC_Data.New()
      Data:Load(arg[3], Network.Results.InputCount, Network.Results.OutputCount, Network.Parameters.Frame)
      Network:Teach(Data)
      Network:Save(arg[4])
    elseif arg[1] == "-W" then
      Network = NC_Network.New()
      Network:Load(arg[2])
      Data = NC_Data.New()
      Data:Load(arg[3], Network.Results.InputCount, 0, Network.Parameters.Frame)
      Results = Network:Work(Data)
      Results:Save(arg[4])
    else
      Write(Log, "# Usage: lua ./Nerea.lua <-T | -W> <Network> <Data> <Network | Results>")
    end
  end
  Seconds = os.time() - Seconds
  Hours = math.floor(Seconds / 3600)
  Seconds = Seconds - Hours * 3600
  Minutes = math.floor(Seconds / 60)
  Seconds = Seconds - Minutes * 60
  Write(Log, string.format("# Elapsed time: %02d:%02d:%02d\n", Hours, Minutes, Seconds))
end

Main()

