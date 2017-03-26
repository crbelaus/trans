# On each test run we destroy any previous test database and
# create it again.
Mix.Task.run "ecto.drop", ["quiet", "-r", "Trans.TestRepo"]
Mix.Task.run "ecto.create", ["quiet", "-r", "Trans.TestRepo"]
Mix.Task.run "ecto.migrate", ["quiet", "-r", "Trans.TestRepo"]

# Start TestRepo process
Trans.TestRepo.start_link
# Start ExMachina
{:ok, _} = Application.ensure_all_started(:ex_machina)
# Run tests
ExUnit.start()

# Destroy test database after test have finished
Mix.Task.run "ecto.drop", ["quiet", "-r", "Trans.TestRepo"]
