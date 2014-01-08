defmodule Upgradex do
  use Application.Behaviour

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    Upgradex.Supervisor.start_link
  end
end

defmodule Upgradex.Git do
	def branch do
		<<"# On branch ", branch::binary>> = System.cmd("git status") 
			|> String.split("\n") 
			|> Enum.first
		branch
	end
	def commit do
		<<"commit ", commit::binary>> = System.cmd("git log") 
			|> String.split("\n") 
			|> Enum.first
		commit
	end
end

defmodule Upgradex.Worker do
	use ExActor, export: Upgradex.Worker
	defrecord State, [branch: nil, commit: nil]
	@timeout 1000

	def init(_) do
		{:ok, State[branch: Upgradex.Git.branch, commit: Upgradex.Git.commit], @timeout}
	end
	definfo :timeout, state: state = State[branch: branch, commit: commit] do
		System.cmd "git pull origin #{branch}"
		case State[branch: Upgradex.Git.branch, commit: Upgradex.Git.commit] do
			new_state = State[commit: ^commit] -> 
				{:noreply, state, @timeout}
			new_state ->
				IO.puts "Need to upgrade!"
				{:noreply, new_state, @timeout}
		end
	end
end