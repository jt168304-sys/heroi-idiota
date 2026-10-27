import numpy as np, json, struct, io
from PIL import Image
import riglib as R, anim
d=np.load('lowpoly.npz')
pos=R.T(d['pos']).astype(np.float32)
nrm=d['nrm'].copy(); nrm[:,0]*=-1; nrm[:,2]*=-1; nrm=nrm.astype(np.float32)
uv=d['uv'].astype(np.float32); tri=d['tri'].astype(np.uint16); J=d['j'].astype(np.uint8); W=d['w'].astype(np.float32)
N=len(pos)
buf=bytearray(); views=[]; accs=[]
def view(data,target=None):
    while len(buf)%4: buf.append(0)
    off=len(buf); buf.extend(data)
    v={'buffer':0,'byteOffset':off,'byteLength':len(data)}
    if target: v['target']=target
    views.append(v); return len(views)-1
def acc(vi,ct,count,typ,mn=None,mx=None):
    a={'bufferView':vi,'componentType':ct,'count':count,'type':typ}
    if mn is not None: a['min']=[float(x) for x in mn]; a['max']=[float(x) for x in mx]
    accs.append(a); return len(accs)-1
a_pos=acc(view(pos.tobytes(),34962),5126,N,'VEC3',pos.min(0),pos.max(0))
a_nrm=acc(view(nrm.tobytes(),34962),5126,N,'VEC3')
a_uv=acc(view(uv.tobytes(),34962),5126,N,'VEC2')
a_j=acc(view(J.tobytes(),34962),5121,N,'VEC4')
a_w=acc(view(W.tobytes(),34962),5126,N,'VEC4')
a_idx=acc(view(tri.reshape(-1).tobytes(),34963),5123,tri.size,'SCALAR')
ibm=[]
for i in range(len(R.NAMES)):
    m=np.eye(4,dtype=np.float32); m[:3,3]=-R.REST_WORLD[i]; ibm.append(m.T.reshape(-1))
a_ibm=acc(view(np.concatenate(ibm).astype(np.float32).tobytes()),5126,len(R.NAMES),'MAT4')
# textura
img=Image.open('tex0.jpg').convert('RGB').resize((1024,1024),Image.LANCZOS)
bio=io.BytesIO(); img.save(bio,'JPEG',quality=88,optimize=True)
v_img=view(bio.getvalue())
nodes=[{'name':'Heroi','mesh':0,'skin':0}]
for i,n in enumerate(R.NAMES):
    nd={'name':n,'translation':[float(x) for x in R.REST_LOCAL[i]]}
    ch=[1+k for k,p in enumerate(R.PARENT) if p==i]
    if ch: nd['children']=ch
    nodes.append(nd)
animations=[]
for name in anim.ANIMS:
    times,fr=anim.frames(name)
    t_arr=np.array(times,np.float32)
    a_t=acc(view(t_arr.tobytes()),5126,len(t_arr),'SCALAR',[t_arr.min()],[t_arr.max()])
    samplers=[]; channels=[]
    # hips translação
    tr=np.array([R.REST_LOCAL[0]+f[1] for f in fr],np.float32)
    a_o=acc(view(tr.tobytes()),5126,len(tr),'VEC3')
    samplers.append({'input':a_t,'output':a_o,'interpolation':'LINEAR'}); channels.append({'sampler':0,'target':{'node':1,'path':'translation'}})
    for bi,b in enumerate(R.NAMES):
        qs=np.array([f[0][b] for f in fr],np.float32)
        for k in range(1,len(qs)):
            if np.dot(qs[k],qs[k-1])<0: qs[k]*=-1
        a_o=acc(view(qs.tobytes()),5126,len(qs),'VEC4')
        samplers.append({'input':a_t,'output':a_o,'interpolation':'LINEAR'})
        channels.append({'sampler':len(samplers)-1,'target':{'node':1+bi,'path':'rotation'}})
    animations.append({'name':name,'samplers':samplers,'channels':channels})
gltf={'asset':{'version':'2.0','generator':'idiota-heroi-pipeline'},
 'scene':0,'scenes':[{'nodes':[0,1]}],'nodes':nodes,
 'meshes':[{'name':'Heroi','primitives':[{'attributes':{'POSITION':a_pos,'NORMAL':a_nrm,'TEXCOORD_0':a_uv,'JOINTS_0':a_j,'WEIGHTS_0':a_w},'indices':a_idx,'material':0}]}],
 'skins':[{'joints':list(range(1,1+len(R.NAMES))),'inverseBindMatrices':a_ibm,'skeleton':1}],
 'materials':[{'name':'heroi','pbrMetallicRoughness':{'baseColorTexture':{'index':0},'metallicFactor':0.0,'roughnessFactor':0.65},'doubleSided':True}],
 'textures':[{'source':0,'sampler':0}],'images':[{'bufferView':v_img,'mimeType':'image/jpeg'}],
 'samplers':[{'magFilter':9729,'minFilter':9987,'wrapS':33071,'wrapT':33071}],
 'accessors':accs,'bufferViews':views,'buffers':[{'byteLength':len(buf)}],'animations':animations}
js=json.dumps(gltf,separators=(',',':')).encode()
while len(js)%4: js+=b' '
while len(buf)%4: buf.append(0)
out=struct.pack('<4sII',b'glTF',2,12+8+len(js)+8+len(buf))+struct.pack('<I4s',len(js),b'JSON')+js+struct.pack('<I4s',len(buf),b'BIN\0')+bytes(buf)
open('heroi.glb','wb').write(out)
print('glb bytes',len(out),'verts',N,'tris',len(tri),'anims',[a['name'] for a in animations])
