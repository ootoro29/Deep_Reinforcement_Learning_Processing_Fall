abstract class layor {

  double alpha = 2.5;
  double mu = 0.9;
  double beta1 = 0.8;//0.5
  double beta2 = 0.8;//0.5
  Matrix z, a, w, b, d, in, vw, vb, vvw, vvb, mmw, mmb;
  int l;
  int state;
  layor(int x) {
    l = x;
    state = 0;
    z = new Matrix(x, 1);
    a = new Matrix(x, 1);
    b = new Matrix(x, 1);
    vb = new Matrix(x, 1);
    vvb = new Matrix(x, 1);
    mmb = new Matrix(x, 1);
    d = new Matrix(x, 1);
    for (int i = 0; i <x; i++) {
      z.Arr[i][0] = 0;
      a.Arr[i][0] = 0;
      vb.Arr[i][0] = 0;
      vvb.Arr[i][0] = 0;
      mmb = new Matrix(x, 1);
    }
  }
  void set_W(int l1) {
    w = new Matrix(l, l1);
    vw = new Matrix(l, l1);
    vvw = new Matrix(l, l1);
    mmw = new Matrix(l, l1);
    for (int i = 0; i < l; i++) {
      for (int j = 0; j < l1; j++) {
        vw.Arr[i][j] = 0;
        vvw.Arr[i][j] = 0;
        mmw.Arr[i][j] = 0;
      }
    }
    w.set_random();

    b.set_random();
  }
  Matrix fw(Matrix F) {
    in = new Matrix(F);
    z.equal_Mat(w.mul_Mat(F).add_Mat(b));


    for (int i = 0; i < l; i++) {
      a.Arr[i][0] = f(z.Arr[i][0]);
    }

    return a;
  }
  Matrix bc(Matrix D, Matrix W) {
    for (int i = 0; i < l; i++) {
      double sum = 0;
      for (int k = 0; k < D.c; k++) {
        sum += D.Arr[k][0]*W.Arr[k][i];
      }
      d.Arr[i][0] = sum;
    }
    for (int i = 0; i < l; i++) {
      d.Arr[i][0] *= df(z.Arr[i][0]);
    }
    return d;
  }

  ArrayList<Double> reset() {
    ArrayList<Double> D = new ArrayList();
    for (int i = 0; i < l; i++) {
      for (int j  =0; j < in.c; j++) {
        D.add(d.Arr[i][0]*in.Arr[j][0]);
      }
      D.add(d.Arr[i][0]);
    }
    return D;
  }

  /*momentum
   
   void reset_W(double size) {
   for (int i = 0; i < l; i++) {
   for (int j  =0; j < in.c; j++) {
   w.Arr[i][j] += -alpha*d.Arr[i][0]*in.Arr[j][0]*size + mu*vw.Arr[i][j];
   vw.Arr[i][j] = -alpha*d.Arr[i][0]*in.Arr[j][0]*size + mu*vw.Arr[i][j];
   }
   b.Arr[i][0] = -alpha*d.Arr[i][0]*size+ mu*vb.Arr[i][0];
   vb.Arr[i][0] = -alpha*d.Arr[i][0]*size+ mu*vb.Arr[i][0];
   }
   }
   */


  void reset_W(double size) {
    for (int i = 0; i < l; i++) {
      for (int j  =0; j < in.c; j++) {
        double gw = d.Arr[i][0]*in.Arr[j][0]*size;

        mmw.Arr[i][j] = beta1*mmw.Arr[i][j] + (1-beta1)*(gw);
        vvw.Arr[i][j] = beta2*vvw.Arr[i][j] + (1-beta2)*(gw)*(gw);
        w.Arr[i][j] += -(alpha/(Math.sqrt(vvw.Arr[i][j])+0.01))*mmw.Arr[i][j];
        //w.Arr[i][j] += -alpha*d.Arr[i][0]*in.Arr[j][0]*size + mu*vw.Arr[i][j];
        //vw.Arr[i][j] = -alpha*d.Arr[i][0]*in.Arr[j][0]*size + mu*vw.Arr[i][j];
      }
      double gb = d.Arr[i][0]*size;
      mmb.Arr[i][0] = beta1*mmb.Arr[i][0] + (1-beta1)*(gb);
      vvb.Arr[i][0] = beta2*vvb.Arr[i][0] + (1-beta2)*(gb)*(gb);
      b.Arr[i][0] = -(alpha/(Math.sqrt(vvb.Arr[i][0])+0.01))*mmb.Arr[i][0];
      //b.Arr[i][0] = -alpha*d.Arr[i][0]*size+ mu*vb.Arr[i][0];
      //vb.Arr[i][0] = -alpha*d.Arr[i][0]*size+ mu*vb.Arr[i][0];
      //println(mmb.Arr[i][0],vvb.Arr[i][0]);
    }
  }


  void act_fun() {
    for (int i = 0; i < l; i ++) {
      a.Arr[i][0] = f(z.Arr[i][0]);
    }
  }
  abstract double f(double x);
  abstract double df(double x);
}

class in_layor extends layor {
  in_layor(int x) {
    super(x);
  }
  double f(double x) {
    return x;
  }
  double df(double x) {
    return x;
  }
}
class hide_layor extends layor {
  hide_layor(int x) {
    super(x);
    alpha = 0.000001;
  }
  double f(double x) {
    return likely_relu(x);
  }
  double df(double x) {
    return Dlikely_relu(x);
  }
}
class out_layor extends layor {
  out_layor(int x) {
    super(x);
    alpha = 0.000001;
  }
  double f(double x) {
    return x;
  }
  double df(double x) {
    return 1;
  }
}

class Neural {
  int N;
  double eta = 1;
  double M = -1;
  ArrayList<layor>net = new ArrayList();
  Matrix ans, in, out;
  Neural(int []size) {
    N = size.length;
    out = new Matrix(size[N-1], 1);
    ans = new Matrix(size[N-1], 1);
    in = new Matrix(size[0], 1);
    net.add(new in_layor(size[0]));
    for (int i = 1; i < N-1; i++) {
      net.add(new hide_layor(size[i]));
    }
    net.add(new out_layor(size[size.length-1]));
    for (int i = 1; i< N; i++) {
      net.get(i).set_W(size[i-1]);
    }
    net.get(0).state = -1;
    net.get(N-1).state = 1;
    for (int i = 1; i< N; i++) {
      net.get(i).set_W(size[i-1]);
    }
  }
  double learning(double []inx, double [] anx) {
    for (int i = 0; i < net.get(0).l; i++) {
      in.Arr[i][0] = inx[i];
    }
    for (int i = 0; i < net.get(N-1).l; i++) {
      ans.Arr[i][0] = anx[i];
    }
    keisan(inx);
    return fix();
  }
  void func(double []inx) {
    for (int i = 0; i < net.get(0).l; i++) {
      in.Arr[i][0] = inx[i];
    }

    keisan(inx);
    dis_Out();
  }
  double[] fun_out(double []inx) {
    for (int i = 0; i < net.get(0).l; i++) {
      in.Arr[i][0] = inx[i];
    }

    keisan(inx);
    int C = out.c;
    double ans[] = new double [C];
    for (int i = 0; i < C; i++) {
      ans[i] = out.Arr[i][0];
    }
    return ans;
  }
  void keisan(double []inx) {
    ArrayList<Matrix>X = new ArrayList();
    X.add(new Matrix(inx));
    for (int i = 1; i < N; i++) {

      //print(i+"->");
      //X.get(X.size()-1).show();
      X.add(net.get(i).fw(X.get(X.size()-1)));
    }
    for (int i = 0; i < X.get(X.size()-1).c; i++) {
      out.Arr[i][0] = X.get(X.size()-1).Arr[i][0];
    }
  }
  void dis_Out() {
    for (int i = 0; i < in.c; i++) {
      //print(in.Arr[i][0], " ");
    }
    print(":-> ");
    for (int i = 0; i < out.c; i++) {
      print(out.Arr[i][0], " ");
    }
    print("\n");
  }
  double delta = 1.0;
  double fix() {
    ArrayList<Matrix>C = new ArrayList();
    Matrix H = new Matrix(net.get(N-1).l, 1);

    for (int i = 0; i < net.get(N-1).l; i++) {
      double cost = net.get(N-1).a.Arr[i][0] - ans.Arr[i][0];
      double del = cost;
      if (cost > delta)del = delta;
      if (cost < -delta)del = -delta;
      H.Arr[i][0] = del;
    }
    C.add(H);
    for (int i = 0; i < net.get(N-1).l; i++) {
      C.get(0).Arr[i][0] *= net.get(N-1).df(net.get(N-1).z.Arr[i][0]);
    }
    for (int i = 0; i < net.get(N-1).l; i++) {
      net.get(N-1).d.Arr[i][0] = C.get(0).Arr[i][0];
    }
    ArrayList<Matrix>W = new ArrayList();
    W.add(new Matrix(net.get(N-1).w));

    for (int i = 0; i < N-1; i++) {
      int index = N-i-2;
      C.add(new Matrix(net.get(index).bc(C.get(C.size()-1), W.get(W.size()-1))));
      if (index != 0)W.add(new Matrix(net.get(index).w));
    }

    double size = 0;
    for (int i = 1; i < N; i++) {
      ArrayList<Double>D = net.get(i).reset();
      for (int j = 0; j < D.size(); j++) {
        size += D.get(j)*D.get(j);
      }
    }
    size = Math.sqrt(size);
    //print(size);
    double ans = size;
    size = Math.min(M/size, 1);
    if (M == -1)size = 1;

    for (int i = 1; i < N; i++) {
      net.get(i).reset_W(size);
    }

    return ans;
  }
}
