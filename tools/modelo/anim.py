import numpy as np
import riglib as R
q=R.qeuler
FPS=30
BONES=R.NAMES
BASE={'upperarm_L':(0,0,10),'upperarm_R':(0,0,-10),'forearm_L':(12,0,0),'forearm_R':(12,0,0)}

def pose_from(d, hips_y=0.0, hips_z=0.0):
    """d: bone -> (rx,ry,rz) graus; soma a base. Retorna (quats dict, hips_t)."""
    out={}
    for b in BONES:
        e=np.array(BASE.get(b,(0,0,0)),float)+np.array(d.get(b,(0,0,0)),float)
        out[b]=q(*e)
    return out,np.array([0,hips_y,hips_z])

def lerp_pose(a,b,t):
    keys=set(a)|set(b); out={}
    for k in keys:
        pa=np.array(a.get(k,(0,0,0)),float); pb=np.array(b.get(k,(0,0,0)),float)
        out[k]=pa+(pb-pa)*t
    return out

def keyframed(keys, t):
    """keys: lista de (tempo, dict_pose, hips_y). interpolação suave entre quadros-chave."""
    ts=[k[0] for k in keys]
    if t<=ts[0]: return keys[0][1],keys[0][2]
    if t>=ts[-1]: return keys[-1][1],keys[-1][2]
    i=max(j for j in range(len(ts)) if ts[j]<=t)
    u=(t-ts[i])/(ts[i+1]-ts[i]); u=u*u*(3-2*u)
    return lerp_pose(keys[i][1],keys[i+1][1],u), keys[i][2]+(keys[i+1][2]-keys[i][2])*u

def idle(t,T=2.4):
    p=2*np.pi*t/T; s=np.sin(p)
    d={'spine':(2+1.5*s,0,0),'chest':(1.5*s,0,0),'head':(-2-1.0*s,0,0),
       'upperarm_L':(2*s,0,2*s),'upperarm_R':(2*s,0,-2*s),
       'thigh_L':(4,0,0),'shin_L':(-6,0,0),'foot_L':(2,0,0),
       'thigh_R':(4,0,0),'shin_R':(-6,0,0),'foot_R':(2,0,0)}
    return pose_from(d,0.012*s-0.015)

def walk(t,T=1.0,amp=1.0,run=False):
    p=2*np.pi*t/T
    A=34 if run else 26          # amplitude da coxa (menor = quadril estável)
    K=105 if run else 60         # flexão do joelho na fase de balanço
    ea=75 if run else 30         # cotovelo dobrado
    aa=38 if run else 26         # balanço do braço (oposto à perna)
    d={}
    for side,ph,sg in (('R',p,1),('L',p+np.pi,-1)):
        s=np.sin(ph); c=np.cos(ph)
        d['thigh_'+side]=(A*s,0,0)
        d['shin_'+side]=(-(K*max(0,c)+8),0,0)     # joelho dobra quando a perna passa por baixo
        d['foot_'+side]=(-0.25*A*s+(8 if run else 4)*max(0,c),0,0)
        d['upperarm_'+side]=(-sg*aa*np.sin(p),0,0)
        d['forearm_'+side]=(ea+12*max(0,-sg*np.cos(p)),0,0)
    lean=5 if run else 2          # tronco quase reto: sem inclinar o quadril
    d['spine']=(lean,(6 if run else 3)*np.sin(p),0)
    d['chest']=(-lean*0.5,-(6 if run else 3)*np.sin(p),0)
    d['head']=(-lean*0.5,0,0)
    bob=(0.035 if run else 0.015)*np.cos(2*p)-(0.02 if run else 0.01)
    return pose_from(d,bob)

def run(t): return walk(t,0.6,1.0,True)

def attack_light(t):
    D=0.55
    rest={}
    keys=[
     (0.00,{'spine':(3,0,0),'thigh_R':(5,0,0),'thigh_L':(5,0,0)},0.0),
     (0.12,{'spine':(0,-28,0),'chest':(0,-10,0),'head':(0,15,0),'upperarm_R':(115,0,-25),'forearm_R':(70,0,0),'upperarm_L':(-20,0,10),'thigh_R':(-8,0,0),'thigh_L':(14,0,0),'shin_L':(-15,0,0)},-0.03),
     (0.24,{'spine':(14,34,0),'chest':(0,12,0),'head':(0,-24,0),'upperarm_R':(38,0,22),'forearm_R':(12,0,0),'upperarm_L':(35,0,-20),'thigh_R':(38,0,0),'shin_R':(-35,0,0),'thigh_L':(-18,0,0)},-0.08),
     (0.38,{'spine':(10,30,0),'head':(0,-20,0),'upperarm_R':(22,0,28),'forearm_R':(10,0,0),'upperarm_L':(30,0,-15),'thigh_R':(30,0,0),'shin_R':(-28,0,0),'thigh_L':(-14,0,0)},-0.07),
     (0.55,{'spine':(3,0,0),'thigh_R':(5,0,0),'thigh_L':(5,0,0)},0.0)]
    p,h=keyframed(keys,min(t,D)); return pose_from(p,h)

def attack_heavy(t):
    D=1.1
    keys=[
     (0.00,{'spine':(3,0,0)},0.0),
     (0.50,{'spine':(-14,-10,0),'chest':(-6,0,0),'head':(8,0,0),'upperarm_R':(165,0,-12),'forearm_R':(45,0,0),'upperarm_L':(-35,0,-38),'forearm_L':(30,0,0),'thigh_R':(-12,0,0),'shin_R':(-25,0,0),'thigh_L':(18,0,0),'shin_L':(-35,0,0)},-0.12),
     (0.60,{'spine':(34,8,0),'chest':(6,0,0),'head':(-14,0,0),'upperarm_R':(32,0,10),'forearm_R':(8,0,0),'upperarm_L':(40,0,-30),'thigh_R':(48,0,0),'shin_R':(-52,0,0),'thigh_L':(-24,0,0),'shin_L':(-12,0,0)},-0.2),
     (0.85,{'spine':(30,6,0),'head':(-12,0,0),'upperarm_R':(30,0,10),'forearm_R':(8,0,0),'upperarm_L':(38,0,-28),'thigh_R':(46,0,0),'shin_R':(-50,0,0),'thigh_L':(-22,0,0)},-0.19),
     (1.10,{'spine':(3,0,0)},0.0)]
    p,h=keyframed(keys,min(t,D)); return pose_from(p,h)

def jump(t):
    D=0.7
    keys=[
     (0.00,{'spine':(3,0,0)},0.0),
     (0.10,{'spine':(14,0,0),'head':(-8,0,0),'thigh_R':(40,0,0),'thigh_L':(40,0,0),'shin_R':(-70,0,0),'shin_L':(-70,0,0),'upperarm_R':(-30,0,0),'upperarm_L':(-30,0,0)},-0.16),
     (0.22,{'spine':(-4,0,0),'thigh_R':(6,0,0),'thigh_L':(6,0,0),'upperarm_R':(70,0,-30),'upperarm_L':(70,0,30),'forearm_R':(20,0,0),'forearm_L':(20,0,0)},0.02),
     (0.45,{'spine':(4,0,0),'thigh_R':(26,0,0),'shin_R':(-45,0,0),'thigh_L':(-8,0,0),'shin_L':(-20,0,0),'upperarm_R':(30,0,-40),'upperarm_L':(30,0,40)},0.0),
     (0.70,{'spine':(6,0,0),'thigh_R':(30,0,0),'shin_R':(-50,0,0),'thigh_L':(-10,0,0),'shin_L':(-22,0,0),'upperarm_R':(25,0,-45),'upperarm_L':(25,0,45)},0.0)]
    p,h=keyframed(keys,min(t,D)); return pose_from(p,h)

def dodge(t):
    D=0.45
    keys=[
     (0.00,{'spine':(3,0,0)},0.0),
     (0.10,{'spine':(36,0,0),'chest':(10,0,0),'head':(-25,0,0),'thigh_R':(55,0,0),'shin_R':(-75,0,0),'thigh_L':(-25,0,0),'shin_L':(-30,0,0),'upperarm_R':(-55,0,-10),'upperarm_L':(-55,0,10),'forearm_R':(40,0,0),'forearm_L':(40,0,0)},-0.28),
     (0.30,{'spine':(40,0,0),'chest':(10,0,0),'head':(-28,0,0),'thigh_R':(60,0,0),'shin_R':(-80,0,0),'thigh_L':(30,0,0),'shin_L':(-70,0,0),'upperarm_R':(-60,0,-10),'upperarm_L':(-60,0,10),'forearm_R':(45,0,0),'forearm_L':(45,0,0)},-0.3),
     (0.45,{'spine':(5,0,0)},0.0)]
    p,h=keyframed(keys,min(t,D)); return pose_from(p,h)

ANIMS={'idle':(idle,2.4,True),'walk':(walk,1.0,True),'run':(run,0.65,True),
       'attack_light':(attack_light,0.55,False),'attack_heavy':(attack_heavy,1.1,False),
       'jump':(jump,0.7,False),'dodge':(dodge,0.45,False)}

def frames(name):
    f,dur,loop=ANIMS[name]
    n=int(round(dur*FPS)); 
    times=[i/FPS for i in range(n+(0 if loop else 1))]
    return times,[f(t) for t in times]
