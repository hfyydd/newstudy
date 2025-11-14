from fastapi.testclient import TestClient

try:
    from .server import app
except ImportError:  # pragma: no cover
    from server import app


def test_curious_student():
    client = TestClient(app)
    response = client.post(
        "/agents/curious-student",
        json={"text": "通货膨胀就是指货币的购买力下降,导致物价普遍上涨。当市场上的货币供应量超过实际需求时,就会出现通货膨胀现象,这会侵蚀居民的实际收入水平。"},
    )
    response.raise_for_status()
    data = response.json()
    assert "reply" in data
    print("Curious student reply:", data["reply"])


def test_simple_explainer():
    client = TestClient(app)
    response = client.post(
        "/agents/simple-explainer",
        json={"text": '{"words":["<购买力>", "<货币供应量>", "<实际需求>", "<侵蚀>", "<实际收入水平>"],"original_context":"通货膨胀就是指货币的购买力下降,导致物价普遍上涨。当市场上的货币供应量超过实际需求时,就会出现通货膨胀现象,这会侵蚀居民的实际收入水平。"}'},
    )
    response.raise_for_status()
    data = response.json()
    assert "reply" in data
    print("Simple explainer reply:", data["reply"])


if __name__ == "__main__":
    test_curious_student()
    test_simple_explainer()


