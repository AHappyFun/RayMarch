Shader "Unlit/RayMarch1"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST 0.01

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };


            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                o.hitPos = v.vertex;
                return o;
            }

            //p点到场景中物体的最近距离
            float GetDist(float3 p) 
            {
                float4 s = float4(0, 0, 0, .5);  //xyz位置w半径
                float sphereDist = length(p - s.xyz) - s.w;   //p到球面的距离
                //float planeDist = p.y;  //p到平面的距离
                
                float d = sphereDist;// min(sphereDist, planeDist);
                return d;
            }

            float RayMarch(float3 ro, float3 rd) 
            {
                float d0 = 0;

                for (int i = 0; i < MAX_STEPS; i++) {
                    float3 p = ro + rd * d0;
                    float ds = GetDist(p);
                    d0 += ds;
                    if (d0 > MAX_DIST || ds < SURF_DIST)
                        break;
                }

                return d0;
            }

            float3 GetNormal(float3 p) 
            {
                float d = GetDist(p);
                float2 e = float2(0.01, 0);

                float3 n = float3(d,d,d) - float3(
                    GetDist(p - e.xyy),
                    GetDist(p - e.yxy),
                    GetDist(p - e.yyx));

                return normalize(n);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float2 uv = i.uv - .5;
                float3 rayOri = i.ro;
                float3 rayDir = normalize(i.hitPos - rayOri);

                float d = RayMarch(rayOri, rayDir);

                fixed4 col = 0;

                if (d >= MAX_DIST) {
                    discard;
                }

                float3 p = rayOri + rayDir * d;
                float3 n = GetNormal(p);
                col.rgb = n;

                return col;
            }
            ENDCG
        }
    }
}
