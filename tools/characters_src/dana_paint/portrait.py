import sys,random,os
sys.path.insert(0,os.path.dirname(__file__))
import painter as P
var=sys.argv[1]; out=sys.argv[2]; P.SS=int(os.environ.get('SS','4')); P.EXPR=os.environ.get('EXPR','base')
YAW=float(os.environ.get('YAW','0.6'));RH=300
W,H=640,640
import math
k=1.1; cy=322 if var=='a' else 300; cx=318
main=P.Canvas(W,H)
def layer(fn,X0,Rc,yaw):
    L=P.Canvas(W,H); fn(L); L.warp(X0,Rc,yaw); main.comp(L)
layer(lambda L:P.draw_head(L,cx,cy,k,var,random.Random(7),'back'),cx,RH*k,YAW)
bx=cx
layer(lambda L:P.draw_shoulders(L,bx,cy,k,0),bx,420*k,YAW*0.55)
layer(lambda L:P.draw_head(L,cx,cy,k,var,random.Random(7),'front'),cx,RH*k,YAW)
layer(lambda L:P.draw_collar(L,bx,cy,k),bx,420*k,YAW*0.55)
main.out(W,H).save(out)
