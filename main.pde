Env Main;
boolean ok = true;
void setup() {
  size(600, 800);
  Main = new Env();
  Main.initialize();
  KeyState.initialize();
}
void draw() {
  if (ok) {
    for (int i = 0; i < 1; i++) {
      Main.doEnv();
    }
  }
  Main.display();

  KeyState.Rini();
  KeyState.mRini();
}
