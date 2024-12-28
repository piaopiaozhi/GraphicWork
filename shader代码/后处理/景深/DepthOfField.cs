using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class DepthOfField : ScreenEffectBase
{
    [Range(0.2f, 3)]
    public float blurSize = 0.6f;
    [Range(0, 4)]
    public int iterations = 3;
    [Range(1, 8)]
    public int downSample = 2;

    [Range(-0.02f, 1.02f)]
    public float focusDistance = 0.5f;

    private Camera myCamera = null;
    public Camera MyCamera
    {
        get
        {
            if(myCamera == null)
                myCamera = GetComponent<Camera>();
            return myCamera;
        }

    }

    private void OnEnable()
    {
        
        MyCamera.depthTextureMode |= DepthTextureMode.Depth;
    }
    private void OnDisable()
    {
        MyCamera.depthTextureMode &= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(Material)
        {
            Material.SetFloat("_FocusDistance", focusDistance);

            var w = source.width / downSample;
            var h = source.height / downSample;

            var buffer0 = RenderTexture.GetTemporary(w, h, 0);
            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(source, buffer0);

            for(int i = 0;  i<iterations;i++)
            {
                Material.SetFloat("_BlurSize", blurSize * i + 1.0f);

                var buffer1 = RenderTexture.GetTemporary(w, h, 0);
                buffer1.filterMode = FilterMode.Bilinear;
                Graphics.Blit(buffer0, buffer1, Material, 0);
                RenderTexture.ReleaseTemporary(buffer0);

                buffer0 = RenderTexture.GetTemporary(w, h, 0);
                Graphics.Blit(buffer1, buffer0, Material, 1);
                RenderTexture.ReleaseTemporary(buffer1);
            }

            Material.SetTexture("_BlurTex", buffer0);
            Graphics.Blit(source, destination, Material, 2);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
