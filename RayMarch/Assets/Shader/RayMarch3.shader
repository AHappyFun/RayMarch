Shader "Unlit/RayMarch3"
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
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            //Cull Off
            
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
                o.ro = _WorldSpaceCameraPos.xyz;
                o.hitPos = mul(unity_ObjectToWorld ,v.vertex);
                
                return o;
            }

            float Box(float3 p, float3 b)
            {
                  float3 q = abs(p) - b;
                  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0);
            }

            //p点到场景中物体的最近距离
            float GetDist(float3 p) 
            {
                float3 box = float3(.5,0.1,.5);
                float3 boxCenter = float3(0,-0.1,0);
                float boxDist = Box(p - boxCenter, box);
                             
                float saita = _Time.y ;
                float sinSaita = sin(saita);
                float cosSaita = cos(saita);
                float3x3 rotate = float3x3(
                    float3(cosSaita, 0, -sinSaita),
                    float3(0, 1, 0),
                    float3(sinSaita,0,cosSaita)
                );

                float3 rotateBoxP = mul(transpose(rotate), p);     

                float3 box2 = float3(.2, .2, .2);
                float3 box2Center = float3(0,.1,0);
                float box2Dist = Box(rotateBoxP - box2Center, box2);                

                float d = max(-box2Dist, boxDist);
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
                float3 rayOri = i.ro;
                float3 rayDir = normalize(i.hitPos - rayOri);

                float d = RayMarch(rayOri, rayDir);

                if (d >= MAX_DIST) {
                    discard;
                }

                float3 worldPos = rayOri + rayDir * d;       
                float3 normal = GetNormal(worldPos);

                Light light = GetMainLight(TransformWorldToShadowCoord(worldPos));


                //shadow
                float d2 = RayMarch(worldPos + normal * SURF_DIST * 2, light.direction);
                if(d2 < length(light.direction - worldPos))
                {
                    light.color *= 0;
                }
                
                float4 shadowCoord = TransformWorldToShadowCoord(worldPos);
                float atten = SAMPLE_TEXTURE2D_SHADOW(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture, shadowCoord.xyz);
           
                light.color *= atten;
                
                half3 diffuse = max(0, dot(normal, light.direction));
               
                float3 finCol = diffuse * light.color;
                
                return half4(finCol, 1);
            }
            
            ENDHLSL
        }

    }
}
