{
  fetchFromGitHub,
  lib,
  python313Packages,
}:

python313Packages.buildPythonApplication {
  pname = "tgsend";
  version = "0.1.0-unstable-2026-03-30";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "gakawarstone";
    repo = "tgsend";
    rev = "64b3c092933fe731c9483f76d4f88c21edb5723f";
    hash = "sha256-CSZcvF/JCnxEBeS6wxAeeqdUPzQXzIALlEz8RMWKptM=";
  };

  build-system = [ python313Packages.setuptools ];

  dependencies = with python313Packages; [
    aiogram
    python-dotenv
  ];

  pythonImportsCheck = [ "tgsend" ];

  meta = {
    description = "Send files and text messages through a Telegram bot";
    homepage = "https://github.com/gakawarstone/tgsend";
    license = lib.licenses.mit;
    mainProgram = "tgsend";
  };
}
