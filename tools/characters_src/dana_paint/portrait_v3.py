import sys,random,os
sys.path.insert(0,os.path.dirname(__file__))
import painter as P
var=sys.argv[1]; out=sys.argv[2]; P.SS=int(os.environ.get('SS','4'))
cv=P.Canvas(640,640); rng=random.Random(7)
cx,cy,k=322,(322 if var=='a' else 300),1.1
# back hair must be behind shoulders for long hair (b); draw order handled inside head; shoulders first
P.draw_head(cv,cx,cy,k,var,random.Random(7),'back')
P.draw_shoulders(cv,cx,cy,k,0)
P.draw_head(cv,cx,cy,k,var,rng,'front')
P.draw_shoulders(cv,cx,cy,k,0,'collar')
cv.out(640,640).save(out)
