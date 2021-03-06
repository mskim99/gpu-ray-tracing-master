// Copyright 2018 Google Inc. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RayTracedObj : MonoBehaviour
{
    public RayTracer rayTracer;

    //
    // Note: These values must match the values kMaterialXxx constants in Shading.cginc.
    //
    public enum MaterialRt
    {
        Invalid = 0,
        Lambertian = 1,
        Metal = 2,
        Dielectric = 3,
    }

    public MaterialRt Material;

    [Range(.01f, 1.5f)]
    public float ColorMultiplier = 1.0f;

    private Matrix4x4 m_lastTransform = Matrix4x4.identity;
    private float m_lastColorMultiplier;
    private Color m_lastColor;

    public List<RayTracer.Triangle> GetObjToTriangles()
    {
        // Careful to handle colorspaces here.
        var albedo = GetComponent<MeshRenderer>().material.color.linear;
        albedo *= ColorMultiplier;

        int[] meshIndices = this.GetComponent<MeshFilter>().sharedMesh.triangles;
        Vector3[] meshVertices = this.GetComponent<MeshFilter>().sharedMesh.vertices;

        List<RayTracer.Triangle> triList = new List<RayTracer.Triangle>();
        triList.Clear();
        for (int i =0; i < meshIndices.Length / 3; i++)
        {
            var tri = new RayTracer.Triangle();
            tri.Albedo = new Vector3(albedo.r, albedo.g, albedo.b);
            tri.v0 = transform.position + meshVertices[meshIndices[3 * i + 0]];
            tri.v1 = transform.position + meshVertices[meshIndices[3 * i + 1]];
            tri.v2 = transform.position + meshVertices[meshIndices[3 * i + 2]];
            tri.Normal = Vector3.Cross(tri.v1 - tri.v0, tri.v2 - tri.v0);
            tri.Material = (int)Material;
            triList.Add(tri);
        }

        return triList;
    }

    void OnEnable()
    {
        rayTracer.NotifySceneChanged();
        m_lastTransform = transform.localToWorldMatrix;
    }

    void OnDisable()
    {
        if (rayTracer != null)
        {
            rayTracer.NotifySceneChanged();
        }
    }

    void Update()
    {
        if (m_lastTransform != transform.localToWorldMatrix
            || m_lastColorMultiplier != ColorMultiplier
            || m_lastColor != GetComponent<MeshRenderer>().material.color)
        {
            m_lastColorMultiplier = ColorMultiplier;
            m_lastColor = GetComponent<MeshRenderer>().material.color;
            m_lastTransform = transform.localToWorldMatrix;
            rayTracer.NotifySceneChanged();
        }
    }
}
