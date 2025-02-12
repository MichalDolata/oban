defmodule Oban.WorkerTest do
  use ExUnit.Case, async: true

  alias Oban.{Job, Worker}

  defmodule BasicWorker do
    use Worker
  end

  defmodule CustomWorker do
    use Worker, queue: "special", max_attempts: 5

    @impl Worker
    def backoff(attempt), do: attempt * attempt

    @impl Worker
    def perform(%Job{args: %{a: a, b: b}}), do: a + b
  end

  describe "new/2" do
    test "building a job through the worker presets options" do
      job = build_job(%{a: 1, b: 2})

      assert job.args == %{a: 1, b: 2}
      assert job.queue == "special"
      assert job.max_attempts == 5
      assert job.worker == "Oban.WorkerTest.CustomWorker"
    end
  end

  describe "backoff/1" do
    test "the default backoff uses an exponential algorithm with a fixed padding" do
      assert BasicWorker.backoff(1) == 17
      assert BasicWorker.backoff(2) == 19
      assert BasicWorker.backoff(4) == 31
      assert BasicWorker.backoff(5) == 47
    end

    test "the backoff can be overridden" do
      assert CustomWorker.backoff(1) == 1
      assert CustomWorker.backoff(2) == 4
      assert CustomWorker.backoff(3) == 9
    end
  end

  describe "perform/1" do
    test "a default implementation is provided" do
      assert :ok = BasicWorker.perform(build_job(%{}))
    end

    test "the implementation may be overridden" do
      job = build_job(%{a: 2, b: 3})

      assert 5 == CustomWorker.perform(job)
    end
  end

  defp build_job(args) do
    args
    |> CustomWorker.new()
    |> Ecto.Changeset.apply_changes()
  end
end
