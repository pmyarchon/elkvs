defmodule Storage.Test do
  use ExUnit.Case, async: false

  @test_key "#{:erlang.ref_to_list(make_ref())}"
  @test_value "test string value"
  @test_value2 "test string value 2"
  @test_ttl 1

  setup do
    Process.sleep(1000)
  end

  test "create a new key" do
    result = Storage.create(@test_key, @test_value, @test_ttl)
    Storage.delete(@test_key)
    assert result
  end

  test "create an existing key" do
    Storage.create(@test_key, @test_value, @test_ttl)
    result = Storage.create(@test_key, @test_value2, @test_ttl)
    Storage.delete(@test_key)
    assert result === false
  end

  test "read existing key" do
    Storage.create(@test_key, @test_value, @test_ttl)
    result = case Storage.lookup(@test_key) do
      {_, _, _, _} -> true
      nil -> false
    end
    Storage.delete(@test_key)
    assert result
  end

  test "read non-existing key" do
    assert Storage.lookup(@test_key) === nil
  end

  test "update an existing key" do
    Storage.create(@test_key, @test_value, @test_ttl)
    result = Storage.update(@test_key, @test_value2, @test_ttl)
    Storage.delete(@test_key)
    assert result
  end

  test "update non-existing key" do
    result = Storage.update(@test_key, @test_value2, @test_ttl)
    assert result === false
  end

  test "delete an existing key" do
    Storage.create(@test_key, @test_value, @test_ttl)
    assert Storage.delete(@test_key)
  end

  test "delete non-existing key" do
    assert Storage.delete(@test_key) === false
  end

  test "cleanup expired keys" do
    Storage.create(@test_key, @test_value, @test_ttl)
    Process.sleep(2000)
    result = case Storage.lookup(@test_key) do
      {_, _, _, _} -> true
      nil -> false
    end
    Storage.delete(@test_key)
    assert result === false
  end
end
