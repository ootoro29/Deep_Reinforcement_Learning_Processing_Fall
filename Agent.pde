class Data {
  double[] S;
  double[] nS;
  int action;
  double reward;
  int flag;
  double size = 0;
  double error = 30;
  Data(double[] S, int action, double reward, double[] nS, int flag) {
    this.S = S;
    this.action = action;
    this.reward = reward;
    this.nS = nS;
    this.flag = flag;
  }
}
class Memory {
  int size = 0;
  double sum_error = 0;
  ArrayList<Data>Dlist = new ArrayList<Data>();
  Memory(int size) {
    this.size = size;
  }
  void add(State S, int action, double reward, State nS, int flag) {
    Dlist.add(new Data(S.normalize_input(), action, reward, nS.normalize_input(), flag));
    while (Dlist.size() > size) {
      Dlist.remove(0);
    }
  }

  Data sample() {
    Data X = Dlist.get(int(random(Dlist.size())));
    /*
    double max = X.size;
     for (int i = 0; i < 100; i++) {
     Data Y = Dlist.get(int(random(Dlist.size())));
     if (max < Y.size || Y.size == 0) {
     max = Y.size;
     X = Y;
     }
     if (max == 0)break;
     }
     */
    return X;
  }
  void set_sum_error() {
    sum_error = 0;
    for (int i = 0; i < Dlist.size(); i++) {
      sum_error += Dlist.get(i).error;
    }
    //println(sum_error);
  }
  Data sample_priority() {
    double p = Math.random();
    Data X = Dlist.get(int(random(Dlist.size())));
    double P = 0;
    double d = 0.5;
    for (int i = 0; i < Dlist.size(); i++) {
      P+=(Dlist.get(i).error+d)/(sum_error+d*Dlist.size());
      if (P >= p) {
        X = Dlist.get(i);
        break;
      }
    }
    return X;
  }
}
class Agent {
  Neural N = new Neural(ilist(6, 128, 64, 64, 3));
  Neural TN = new Neural(ilist(6, 128, 64, 64, 3));
  double gamma = 0.99;
  Env E;
  int step = 0;
  State S;
  State nS;
  int action = 0;
  double[] NN_out;
  Memory Mem;
  boolean MAJI;
  double end_epsilon = 0.01;
  double start_epsilon = 0.5;
  double delay_epsilon = 0.01;
  double epsilon;
  int rnd = 0;
  int rnd_time = 0;
  Agent(Env E, boolean MAJI) {
    this.E = E;
    this.MAJI = MAJI;
    Mem = new Memory(60000);
    setT();
  }
  int action(State s) {
    //println(Mem.Dlist.size());
    S = s.clone();
    NN_out = N.fun_out(S.normalize_input());
    int act = argmax(NN_out);
    /*
    if (KeyState.get(LEFT)) {
     act = 1;
     }
     if (KeyState.get(RIGHT)) {
     act = 2;
     }
     */
    if (!MAJI) {
      int st = step;
      epsilon = end_epsilon-(end_epsilon-start_epsilon)*Math.exp(-st/100 * delay_epsilon);
      //epsilon = 0.005;
      if (Math.random() < epsilon && rnd_time == 0) {
        rnd = int(random(3));
        rnd_time = int(random(10, 60));
      }
      if (rnd_time > 0) {
        rnd_time--;
        if (rnd_time > 0)act = rnd;
      }
    }
    action = act;
    return act;//(int)random(3);
  }
  boolean ran_greedy() {
    return (rnd_time > 0) && !MAJI;
  }
  void memSet(State ns, double reward, int flag) {
    nS = ns.clone();
    Mem.add(S, action, reward, nS, flag);
  }
  void setT() {
    for (int i = 1; i < TN.net.size(); i++) {
      for (int j = 0; j < TN.net.get(i).w.r; j++) {
        for (int k = 0; k < TN.net.get(i).w.c; k++) {
          TN.net.get(i).w.Arr[k][j] = N.net.get(i).w.Arr[k][j];
        }
      }
      for (int j = 0; j < TN.net.get(i).b.c; j++) {
        TN.net.get(i).b.Arr[j][0] = N.net.get(i).b.Arr[j][0];
      }
    }
  }
  double fit(int batch_size) {
    double ans = 0;
    Mem.set_sum_error();
    if (MAJI)return ans;
    int cnt = 0;
    for (int i = 0; i < batch_size; i++) {
      Data D = Mem.sample_priority();
      double target = 0;
      if (D.flag == 0) {
        target = D.reward+gamma*TN.fun_out(D.nS)[argmax(N.fun_out(D.nS))];
      }
      if (D.flag == 1) {
        target = D.reward;
        cnt++;
      }
      double X = N.fun_out(D.S)[D.action];
      double[] Ans = TN.fun_out(D.S);
      Ans[D.action] = target;

      double size = N.learning(D.S, Ans);

      //println(Math.abs(X-target), Math.abs(N.fun_out(D.S)[D.action]-target), Math.abs(N.fun_out(D.S)[D.action]-target)-Math.abs(X-target), size);
      //if (D.flag==1)println(Math.abs(X-target), Math.abs(N.fun_out(D.S)[D.action]-target), size);
      double[] Y = N.fun_out(D.S);
      D.size = size;
      double error = 0;
      for (int j = 0; j < 3; j++) {
        error += Math.abs(Y[j]-Ans[j]);
      }
      D.error = error;
      ans += error;
    }
    println("FLAG_CNT:"+cnt);
    return ans/batch_size;
  }


  void loadN(String FN) {
    String S[] = loadStrings(FN);
    int index = 0;
    for (int i = 1; i < N.net.size(); i++) {
      for (int j = 0; j < N.net.get(i).w.r; j++) {
        String load[] = S[index].split(",");
        for (int k = 0; k < N.net.get(i).w.c; k++) {
          N.net.get(i).w.Arr[k][j] = Double.parseDouble(load[k]);
        }
        index++;
      }
      String load[] = S[index].split(",");
      for (int j = 0; j< N.net.get(i).b.c; j++) {
        N.net.get(i).b.Arr[j][0] = Double.parseDouble(load[j]);
      }
      index ++;
    }
    String X[] = S[index].split(",");
    step = parseInt(X[0]);

    setT();
  }
  void saveN(String FN) {
    int n = 0;
    for (int i = 0; i < N.net.size()-1; i++) {
      n += N.net.get(i).l + 1;
    }
    n+=3;
    String Save[] = new String[n];
    for (int i = 0; i < n; i++) {
      Save[i] = "";
    }
    int index = 0;
    for (int i = 1; i < N.net.size(); i++) {
      for (int j = 0; j < N.net.get(i).w.r; j++) {
        for (int k = 0; k < N.net.get(i).w.c; k++) {
          Save[index] += String.valueOf(N.net.get(i).w.Arr[k][j]) + ",";
        }
        index++;
      }
      for (int j = 0; j< N.net.get(i).b.c; j++) {
        Save[index] += String.valueOf(N.net.get(i).b.Arr[j][0]) + ",";
      }
      index ++;
    }
    Save[index] += step+",";
    saveStrings(FN, Save);
  }
}
