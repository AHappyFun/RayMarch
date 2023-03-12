Shader "Unlit/RayMarch2"
{
    Properties
    {
        
    }
    SubShader
    {
        Tags{"RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" "UniversalMaterialType" = "Lit" "IgnoreProjector" = "True" "ShaderModel"="4.5"}

        LOD 100

        Pass
        {
            Cull Off
            
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag            
            
            #define MAX_STEPS 100
            #define MAX_DIST 100.
            #define SURF_DIST 0.001

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

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
                o.vertex = TransformObjectToHClip(v.vertex);
                o.uv = v.uv;
                o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                //o.ro = _WorldSpaceCameraPos.xyz;
                o.hitPos = v.vertex;
                //o.hitPos = mul(unity_ObjectToWorld ,v.vertex);
                
                return o;
            }

            float Sphere(float3 p, float s)
            {
                return length(p) - s;
            }

            float Box(float3 p, float3 b)
            {
                  float3 q = abs(p) - b;
                  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }

            //p点到场景中物体的最近距离
            float GetDist(float3 p) 
            {
                float4 s = float4(0, 0.13, 0, .2);  //xyz位置w半径
                float sphereDist = Sphere(p - s.xyz, s.w);   //p到球面的距离

                float3 box = float3(.4,.1,.4);
                float3 boxCenter = float3(0,0,0);
                float boxDist = Box(p - boxCenter, box);
                
                float planeDist = p.y;  //p到平面的距离
                
                float d =  max(-boxDist, sphereDist);

                d = max(-sphereDist, boxDist);
                
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

            half4 frag(v2f i) : SV_Target
            {
                float2 uv = (i.uv - .5) * 2;

                float3 rayOri = i.ro;
                float3 rayDir = normalize(i.hitPos - rayOri);

                float d = RayMarch(rayOri, rayDir);

                half4 col = 0;

                if (d >= MAX_DIST) {
                    discard;
                }

                float3 p = rayOri + rayDir * d;
                float3 n = GetNormal(p);

                p = mul(unity_ObjectToWorld, p);
                
                col.rgb = n;

                Light light = GetMainLight(TransformWorldToShadowCoord(p));


                float3 worldLightDir = normalize(light.direction);
                col.rgb = dot(n, worldLightDir);

                return col;
            }
            ENDHLSL
        }
    }
}
