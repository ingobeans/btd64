import re

with open("btd64.p8", "r") as file:
    content = file.read()

def replace_multiplications(match):
    num1, num2 = map(float, match.groups())
    result = num1 * num2
    return str(int(result)) if result.is_integer() else str(result)

pattern = r'(\d+(?:\.\d+)?)\s*\*\s*(\d+(?:\.\d+)?)'
new_content = re.sub(pattern, replace_multiplications, content)

with open("btd64.p8", "w") as file:
    file.write(new_content)

print("All multiplication expressions between numbers have been replaced.")
