# For now, I don't want game engine to be started on telegram_bot app since I will start it by test
# with start_supervised/1.
Application.stop(:engine)

ExUnit.start()
