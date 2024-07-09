class Env {
  State main;
  Agent P;
  float Player_width = 140;
  float Player_height = 30;
  float Player_y;
  float Ball_R = 20;
  double g = 0.3;
  double reward = 0;
  double score = 0;
  boolean confBall = false;
  boolean done = false;
  int turn = 0;
  int total_turn = 0;
  double total_score = 0;
  int cnt = 0;
  Env() {
    Player_y = height-100;
    P = new Agent(this, true);
    P.loadN("Agent.txt");
  }
  void initialize() {
    //cnt = 0;
    main = new State(width/2, 0, random(0, width), random(30, height-500), random(-5, 5), random(-5, 5));
    total_score += score;
    total_turn += turn;
    reward = 0;
    score = 0;
    confBall = false;
    done = false;
    turn = 0;
    if (!P.MAJI)P.step++;
    if (P.step%100==0 && P.step!=0) {
      total_turn = 0;
      total_score = 0;
    }
  }
  void doEnv() {
    cnt++;
    if (!done) {
      main = process(main);
      reward = Rew(main);
      score += reward;
      P.memSet(main, reward, 0);
      turn ++;

      if (turn > 600&&!P.MAJI) {
        //initialize();
      }
    } else {
      P.S = main.clone();
      reward = Rew(main);
      score += reward;
      P.memSet(main, reward, 1);
      initialize();
      if (P.step%100 == 0) {
        P.setT();
      }
      if (P.step% 100 == 0 && P.step != 0 && !P.MAJI)P.saveN("Agent.txt");
      if (P.step% 1000 == 0 && P.step != 0 && !P.MAJI)P.saveN("data3/"+P.step+"/Agent.txt");
    }
    println("-------------");
    for (int i = 0; i < 1; i++) {
      //P.fit(32);
      println(P.fit(32));
    }
    println("-------------");
  }
  double Rew(State s) {
    double aX = s.AgentX;
    //double aSp = s.AgentSp;
    double ballX = s.BallX;
    double ballY = s.BallY;
    //double ballSpX = s.BallSpX;
    double ballSpY = s.BallSpY;

    if (done) {
      return -5-0.00075*Math.abs((aX+Player_width/2) - ballX);
    }
    double ans = 0;

    if (ballY < Player_y) {
      if (ballSpY < 0)ans += (1.25-0.0055*Math.abs((width/2) - ballX))*0.1;
      else ans += (0.5-0.007*Math.abs((width/2) - ballX))*0.01;
    } else {
      ans += -0.005;
    }
    if (aX <= 0 + 40 || aX >= width - Player_width - 40) {
      ans -= 0.1;
    }
    return ans;
  }

  State process(State s) {
    double aX = s.AgentX;
    double aSp = s.AgentSp;
    double ballX = s.BallX;
    double ballY = s.BallY;
    double ballSpX = s.BallSpX;
    double ballSpY = s.BallSpY;
    int action = P.action(s);
    if (action == 1) {
      aSp -= 0.5;
    }
    if (action == 2) {
      aSp += 0.5;
    }
    aX += aSp;
    aSp*=0.97;

    if (aX < 0) {
      aX = 0;
      aSp = 0;
    }
    if (aX > width-Player_width) {
      aX = width-Player_width;
      aSp = 0;
    }

    ballX += ballSpX;
    ballSpY += g;
    ballY += ballSpY;

    if (ballX < Ball_R) {
      ballX = Ball_R;
      ballSpX *= -1;
    }
    if (ballX > width-Ball_R) {
      ballX = width-Ball_R;
      ballSpX *= -1;
    }
    if (ballY < Ball_R) {
      ballY = Ball_R;
      ballSpY *= -1;
    }

    if (!confBall) {
      if (aX <= ballX && ballX <= aX + Player_width && Player_y-ballY > 0 && Player_y-ballY < Ball_R) {
        confBall = true;
        ballY = Player_y - Ball_R;
        ballSpY *= -1.002;
        if (aX != 0 && aX != width-Player_width)ballSpX += -aSp*0.2;
      } else if (aX <= ballX && ballX <= aX + Player_width && ballY-Player_y > 0 && ballY-Player_y < Ball_R) {
        confBall = true;
        ballY = Player_y + Ball_R;
        ballSpY *= -1.002;
        if (aX != 0 && aX != width-Player_width)ballSpX += -aSp*0.2;
      } else if (Player_y <= ballY && ballY <= Player_y + Player_height && Math.abs(aX-ballX) <Ball_R) {
        confBall = true;
        ballSpX *= -1;
        if (aX != 0 && aX != width-Player_width)ballSpX += -aSp*0.2;
      } else if (dist(ballX, ballY, aX, Player_y) < Ball_R ||dist(ballX, ballY, aX+Player_width, Player_y) < Ball_R||dist(ballX, ballY, aX, Player_y+Player_height) < Ball_R ||dist(ballX, ballY, aX+Player_width, Player_y+Player_height) < Ball_R) {
        confBall = true;
        ballSpX *= -1;
        ballSpY *= -1.002;
        if ((aX != 0 && aX != width-Player_width))ballSpX += -aSp*0.2;
      }
    } else {
      if (aX <= ballX && ballX <= aX + Player_width && Player_y-ballY > 0 && Player_y-ballY < Ball_R) {
      } else if (aX <= ballX && ballX <= aX + Player_width && ballY-Player_y > 0 && ballY-Player_y < Ball_R) {
      } else if (Player_y <= ballY && ballY <= Player_y + Player_height && Math.abs(aX-ballX) <Ball_R) {
      } else if (dist(ballX, ballY, aX, Player_y) < Ball_R ||dist(ballX, ballY, aX+Player_width, Player_y) < Ball_R||dist(ballX, ballY, aX, Player_y+Player_height) < Ball_R ||dist(ballX, ballY, aX+Player_width, Player_y+Player_height) < Ball_R) {
      } else {
        confBall = false;
      }
    }

    if (ballY > height)done = true;

    return new State(aX, aSp, ballX, ballY, ballSpX, ballSpY);
  }

  void display() {
    background(255);
    stroke(0);
    strokeWeight(5);
    fill(255);
    rect((float)main.AgentX, Player_y, Player_width, Player_height);
    ellipse((float)main.BallX, (float)main.BallY, Ball_R*2, Ball_R*2);
    stroke(255, 0, 0);
    translate((float)main.BallX, (float)main.BallY);
    line(0, 0, (float)main.BallSpX*10, (float)main.BallSpY*10);
    translate(-(float)main.BallX, -(float)main.BallY);
    stroke(0, 0, 255);
    translate((float)main.AgentX+Player_width/2, Player_y+Player_height/2);
    line(0, 0, (float)main.AgentSp*10, 0);
    translate(-(float)main.AgentX-Player_width/2, -Player_y-Player_height/2);
    stroke(0);
    fill(0);
    textSize(40);
    text("Step:"+P.step, 0, 50);
    String[] S = {".", "←", "→"};
    for (int i = 0; i < 3; i++) {
      text(S[i]+(float)P.NN_out[i], 0, 90+40*i);
    }
    text("Turn:"+turn+", AVE_Turn:"+((float)total_turn/(P.step%100)), 0, 220);
    text("SCORE:"+score+",\n AVE_SCORE:"+(total_score/(P.step%100)), 0, 260);
    text("Epsilon:"+P.epsilon, 0, 340);
    fill(0);
    if (P.ran_greedy())fill(255, 0, 0);

    textSize(40);
    text(S[P.action], ((float)main.AgentX*2+Player_width)/2, Player_y-50);
  }
}

class State {
  double AgentX;
  double AgentSp;
  double BallX, BallY;
  double BallSpX, BallSpY;
  int dim = 6;
  State(double AgentX, double AgentSp, double BallX, double BallY, double BallSpX, double BallSpY) {
    this.AgentX = AgentX;
    this.AgentSp = AgentSp;
    this.BallX = BallX;
    this.BallY = BallY;
    this.BallSpX = BallSpX;
    this.BallSpY = BallSpY;
  }
  double[] normalize_input() {
    double[] ans = new double[dim];
    ans[0] = AgentX/width;
    ans[1] = AgentSp*0.1;
    ans[2] = BallX/width;
    ans[3] = BallY/height;
    ans[4] = BallSpX*0.1;
    ans[5] = BallSpY*0.1;
    return ans;
  }
  State clone() {
    return new State(AgentX, AgentSp, BallX, BallY, BallSpX, BallSpY);
  }
}
