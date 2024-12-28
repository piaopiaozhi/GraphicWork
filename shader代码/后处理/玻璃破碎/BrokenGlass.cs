using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;

[ExecuteInEditMode()]
public class BrokenGalss : MonoBehaviour
{
    public Material material;


   

    private void Start()
    {
        if (material == null || SystemInfo.supportsImageEffects == false 
            || material.shader == null
            || material.shader.isSupported == false)
        {
            enabled = false;
            return;
        }
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
       
        Graphics.Blit(source, destination,material,0);
    }
}
    