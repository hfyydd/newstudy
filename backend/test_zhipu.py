import os
import sys
from pathlib import Path
from dotenv import load_dotenv

# 加载 .env
env_path = Path(__file__).parent / ".env"
load_dotenv(dotenv_path=env_path)

print(f"Loaded .env from: {env_path}")
print(f"BASE_URL: {os.getenv('BASE_URL')}")
print(f"API_KEY: {os.getenv('API_KEY')[:10]}******")
print(f"MODEL: {os.getenv('MODEL')}")

try:
    from langchain_openai import ChatOpenAI
    from langchain_core.messages import HumanMessage
except ImportError:
    print("Error: langchain libraries not installed. Please run: pip install langchain-openai langchain-core")
    sys.exit(1)

def test_api():
    print("\n--- Testing API Connection ---")
    try:
        llm = ChatOpenAI(
            api_key=os.getenv("API_KEY"),
            base_url=os.getenv("BASE_URL"),
            model=os.getenv("MODEL"),
            temperature=0.7,
        )
        
        print("Model initialized. Sending request...")
        messages = [HumanMessage(content="Hello, are you working?")]
        response = llm.invoke(messages)
        
        print("\n✅ Success!")
        print(f"Response: {response.content}")
        return True
    except Exception as e:
        print(f"\n❌ Failed!")
        print(f"Error type: {type(e)}")
        print(f"Error message: {e}")
        return False

if __name__ == "__main__":
    test_api()
