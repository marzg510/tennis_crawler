module ConfigLoader
  def self.load(file)
    mod = Module.new
    mod.module_eval File.read(file)
    mod
  end
end
